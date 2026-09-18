import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import 'glass.dart';

class PlaceAutocompleteField extends StatefulWidget {
  const PlaceAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.onSelected,
    this.bare = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final ValueChanged<PlaceSuggestion>? onSelected;
  final bool bare;

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  Timer? debounce;
  List<PlaceSuggestion> results = const [];
  bool open = false;
  bool loading = false;
  int requestId = 0;

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        results = const [];
        open = false;
        loading = false;
      });
      return;
    }
    debounce?.cancel();
    final currentRequest = ++requestId;
    setState(() => loading = true);
    debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final found = await apiClient.searchPlaces(value);
        if (!mounted || currentRequest != requestId) return;
        if (found.isEmpty) {
          setState(() {
            results = const [];
            open = false;
            loading = false;
          });
          return;
        }
        setState(() {
          results = found;
          open = true;
          loading = false;
        });
      } catch (_) {
        if (mounted && currentRequest == requestId) {
          setState(() {
            results = const [];
            open = false;
            loading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.bare)
          _BareRouteField(
            label: widget.label,
            hint: widget.hint,
            controller: widget.controller,
            onChanged: _onChanged,
          )
        else
          GlassField(
            label: widget.label,
            hint: widget.hint,
            icon: widget.icon,
            controller: widget.controller,
            onChanged: _onChanged,
            helper: results.isEmpty ? null : 'Sugerencias en tiempo real',
          ),
        if (widget.bare && results.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Text(
              'Sugerencias en tiempo real',
              style: TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 10,
                fontFamily: 'Acumin Pro',
              ),
            ),
          ),
        if (widget.bare && loading)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.white.withValues(alpha: .08),
                color: Colors.white.withValues(alpha: .72),
              ),
            ),
          ),
        if (open && results.isNotEmpty) ...[
          const SizedBox(height: 7),
          LimitOverlay(
            maxHeight: 235,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1C53).withValues(alpha: .84),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: .28)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final suggestion = results[index];
                      return InkWell(
                        onTap: () async {
                          widget.controller.text = suggestion.description;
                          var resolved = suggestion;
                          if (suggestion.latitude == null ||
                              suggestion.longitude == null) {
                            final detail =
                                await apiClient.placeDetail(suggestion.placeId);
                            if (detail != null && detail.latitude != null) {
                              resolved = PlaceSuggestion(
                                placeId: suggestion.placeId,
                                description: suggestion.description,
                                main: suggestion.main,
                                secondary: suggestion.secondary,
                                latitude: detail.latitude,
                                longitude: detail.longitude,
                              );
                            }
                          }
                          widget.onSelected?.call(resolved);
                          if (!mounted) return;
                          FocusScope.of(context).unfocus();
                          setState(() => open = false);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          child: Row(
                            children: [
                              Icon(
                                index == 0
                                    ? Icons.near_me_rounded
                                    : Icons.place_outlined,
                                color: Colors.white.withValues(alpha: .86),
                                size: 17,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      suggestion.main,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Acumin Pro',
                                      ),
                                    ),
                                    if (suggestion.secondary.isNotEmpty)
                                      Text(
                                        suggestion.secondary,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xB3FFFFFF),
                                          fontSize: 10.5,
                                          fontFamily: 'Acumin Pro',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        ],
      ],
    );
  }
}

class LimitOverlay extends StatelessWidget {
  const LimitOverlay({super.key, required this.child, this.maxHeight});

  final Widget child;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight ?? 240),
      child: child,
    );
  }
}

class _BareRouteField extends StatelessWidget {
  const _BareRouteField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xD9FFFFFF),
            fontSize: 9,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
            fontFamily: 'Acumin Pro',
          ),
        ),
        const SizedBox(height: 3),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'Acumin Pro',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'Acumin Pro',
            ),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    );
  }
}
