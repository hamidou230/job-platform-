import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/my_offers_providers.dart';

class CreateOfferScreen extends ConsumerStatefulWidget {
  const CreateOfferScreen({super.key});
  @override
  ConsumerState<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends ConsumerState<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _salaryMin = TextEditingController();
  final _salaryMax = TextEditingController();
  final _skills = TextEditingController();

  String _type = 'INTERNSHIP';
  String _experience = 'JUNIOR';
  bool _isRemote = false;
  bool _submitting = false;

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
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _salaryMin.dispose();
    _salaryMax.dispose();
    _skills.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final body = <String, dynamic>{
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'type': _type,
      'experienceLevel': _experience,
      'isRemote': _isRemote,
      'status': 'OPEN',
      if (_location.text.trim().isNotEmpty) 'location': _location.text.trim(),
      if (_skills.text.trim().isNotEmpty) 'requiredSkills': _skills.text.trim(),
    };
    final min = int.tryParse(_salaryMin.text.trim());
    final max = int.tryParse(_salaryMax.text.trim());
    if (min != null) body['salaryMin'] = min;
    if (max != null) body['salaryMax'] = max;

    final err = await ref.read(myOffersProvider.notifier).create(body);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (err == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offre publiée ✅')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle offre')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'Titre du poste *', prefixIcon: Icon(Icons.title)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description *',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 10) ? '10 caractères minimum' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                  labelText: 'Type de contrat', prefixIcon: Icon(Icons.work_outline)),
              items: _types.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _experience,
              decoration: const InputDecoration(
                  labelText: 'Niveau d\'expérience', prefixIcon: Icon(Icons.badge_outlined)),
              items: _levels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _experience = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                  labelText: 'Ville', prefixIcon: Icon(Icons.location_on_outlined)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _salaryMin,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Salaire min (MAD)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _salaryMax,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Salaire max (MAD)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _skills,
              decoration: const InputDecoration(
                labelText: 'Compétences (séparées par des virgules)',
                prefixIcon: Icon(Icons.code),
                hintText: 'Flutter, Dart, REST',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Télétravail possible'),
              value: _isRemote,
              onChanged: (v) => setState(() => _isRemote = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22, width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Publier l\'offre'),
            ),
          ],
        ),
      ),
    );
  }
}
