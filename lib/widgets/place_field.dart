import 'dart:async';

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
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final ValueChanged<PlaceSuggestion>? onSelected;

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  Timer? debounce;
  List<PlaceSuggestion> results = const [];
  bool open = false;
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
      });
      return;
    }
    debounce?.cancel();
    final currentRequest = ++requestId;
    debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final found = await apiClient.searchPlaces(value);
        if (!mounted || currentRequest != requestId) return;
        if (found.isEmpty) {
          return;
        }
        setState(() {
          results = found;
          open = true;
        });
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassField(
          label: widget.label,
          hint: widget.hint,
          icon: widget.icon,
          controller: widget.controller,
          onChanged: _onChanged,
          helper: results.isEmpty ? null : 'Sugerencias de Managua',
        ),
        if (open && results.isNotEmpty) ...[
          const SizedBox(height: 7),
          LimitOverlay(
            maxHeight: 235,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1D4D).withValues(alpha: .96),
                  border: Border.all(color: glassBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final suggestion = results[index];
                    return InkWell(
                      onTap: () {
                        widget.controller.text = suggestion.description;
                        widget.onSelected?.call(suggestion);
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
                              color: index == 0 ? mint : cyan,
                              size: 17,
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                        color: Color(0xFFB9D4FF),
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
