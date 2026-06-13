import 'package:flutter/material.dart';
import '../../data/offers_repository.dart';

/// Feuille modale de filtres (type, télétravail, niveau d'expérience, ville).
class FilterSheet extends StatefulWidget {
  final OfferFilters initial;
  const FilterSheet({super.key, required this.initial});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String? _type;
  bool? _remote;
  String? _experience;
  late final TextEditingController _location;

  static const _types = {
    'INTERNSHIP': 'Stage',
    'JOB': 'Emploi',
    'ALTERNANCE': 'Alternance',
    'PART_TIME': 'Temps partiel',
  };
  static const _levels = {
    'JUNIOR': 'Junior',
    'INTERMEDIATE': 'Intermédiaire',
    'SENIOR': 'Senior',
  };

  @override
  void initState() {
    super.initState();
    _type = widget.initial.type;
    _remote = widget.initial.isRemote;
    _experience = widget.initial.experienceLevel;
    _location = TextEditingController(text: widget.initial.location ?? '');
  }

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.pop(
      context,
      OfferFilters(
        search: widget.initial.search,
        type: _type,
        isRemote: _remote,
        experienceLevel: _experience,
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      ),
    );
  }

  void _reset() {
    Navigator.pop(context, OfferFilters(search: widget.initial.search));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filtres', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(onPressed: _reset, child: const Text('Réinitialiser')),
            ],
          ),
          const SizedBox(height: 8),
          Text('Type de contrat', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _types.entries.map((e) {
              final selected = _type == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => setState(() => _type = selected ? null : e.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Niveau d\'expérience', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _levels.entries.map((e) {
              final selected = _experience == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => setState(() => _experience = selected ? null : e.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Télétravail uniquement'),
            value: _remote ?? false,
            onChanged: (v) => setState(() => _remote = v ? true : null),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Ville',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _apply, child: const Text('Appliquer les filtres')),
          ),
        ],
      ),
    );
  }
}
