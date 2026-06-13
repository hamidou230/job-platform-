import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider.select((s) => s.user));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final displayName = user.student?.fullName ?? user.company?.name ?? user.email;
    final roleLabel = switch (user.role) {
      UserRole.student => 'Étudiant',
      UserRole.company => 'Entreprise',
      UserRole.admin => 'Administrateur',
      _ => '—',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    displayName.characters.first.toUpperCase(),
                    style: TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 12),
                Text(displayName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                Chip(
                  label: Text(roleLabel),
                  backgroundColor: cs.secondaryContainer,
                  labelStyle: TextStyle(color: cs.onSecondaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (user.role == UserRole.student) ..._studentSections(context, ref, user),
          if (user.role == UserRole.company) ..._companySections(context, ref, user),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  List<Widget> _studentSections(BuildContext context, WidgetRef ref, AppUser user) {
    final s = user.student!;
    final theme = Theme.of(context);
    final action = ref.watch(profileProvider);

    return [
      // ----- Carte CV -----
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Mon CV',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                s.cvUrl != null
                    ? 'CV enregistré. Il sera joint à vos candidatures.'
                    : 'Aucun CV. Ajoutez un fichier PDF, DOC ou DOCX (max 5 Mo).',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: action.isUploadingCv ? null : () => _pickAndUploadCv(context, ref),
                icon: action.isUploadingCv
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(s.cvUrl != null ? Icons.refresh : Icons.upload_file),
                label: Text(s.cvUrl != null ? 'Remplacer le CV' : 'Téléverser un CV'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      // ----- Infos -----
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Informations',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _editStudent(context, ref, user),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _row(context, Icons.school_outlined, 'Université', s.university),
              _row(context, Icons.menu_book_outlined, 'Filière', s.fieldOfStudy),
              _row(context, Icons.calendar_today_outlined, 'Diplôme',
                  s.graduationYear?.toString()),
              _row(context, Icons.phone_outlined, 'Téléphone', s.phone),
              _row(context, Icons.info_outline, 'Bio', s.bio),
              if (s.skillList.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Compétences', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: s.skillList.map((e) => Chip(label: Text(e))).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _companySections(BuildContext context, WidgetRef ref, AppUser user) {
    final c = user.company!;
    final theme = Theme.of(context);
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Entreprise',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _editCompany(context, ref, user),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _row(context, Icons.business_outlined, 'Secteur', c.industry),
              _row(context, Icons.location_on_outlined, 'Localisation', c.location),
              _row(context, Icons.info_outline, 'Description', c.description),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _row(BuildContext context, IconData icon, String label, String? value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              (value == null || value.isEmpty) ? 'Non renseigné' : value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadCv(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: false,
    );
    if (result == null || result.files.single.path == null) return;
    final file = result.files.single;
    final err = await ref.read(profileProvider.notifier).uploadCv(
          filePath: file.path!,
          fileName: file.name,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'CV téléversé ✅'),
          backgroundColor: err != null ? Theme.of(context).colorScheme.error : null,
        ),
      );
    }
  }

  Future<void> _editStudent(BuildContext context, WidgetRef ref, AppUser user) async {
    final s = user.student!;
    final controllers = {
      'university': TextEditingController(text: s.university ?? ''),
      'fieldOfStudy': TextEditingController(text: s.fieldOfStudy ?? ''),
      'graduationYear': TextEditingController(text: s.graduationYear?.toString() ?? ''),
      'phone': TextEditingController(text: s.phone ?? ''),
      'bio': TextEditingController(text: s.bio ?? ''),
      'skills': TextEditingController(text: s.skills ?? ''),
    };
    await _editSheet(
      context,
      ref,
      title: 'Modifier mon profil',
      fields: [
        _FieldDef('university', 'Université', Icons.school_outlined),
        _FieldDef('fieldOfStudy', 'Filière', Icons.menu_book_outlined),
        _FieldDef('graduationYear', 'Année de diplôme', Icons.calendar_today_outlined,
            number: true),
        _FieldDef('phone', 'Téléphone', Icons.phone_outlined),
        _FieldDef('bio', 'Bio', Icons.info_outline, maxLines: 3),
        _FieldDef('skills', 'Compétences (séparées par des virgules)', Icons.code, maxLines: 2),
      ],
      controllers: controllers,
      onSave: () {
        final body = <String, dynamic>{
          'university': controllers['university']!.text.trim(),
          'fieldOfStudy': controllers['fieldOfStudy']!.text.trim(),
          'phone': controllers['phone']!.text.trim(),
          'bio': controllers['bio']!.text.trim(),
          'skills': controllers['skills']!.text.trim(),
        };
        final yr = int.tryParse(controllers['graduationYear']!.text.trim());
        if (yr != null) body['graduationYear'] = yr;
        return ref.read(profileProvider.notifier).updateStudent(body);
      },
    );
  }

  Future<void> _editCompany(BuildContext context, WidgetRef ref, AppUser user) async {
    final c = user.company!;
    final controllers = {
      'industry': TextEditingController(text: c.industry ?? ''),
      'location': TextEditingController(text: c.location ?? ''),
      'description': TextEditingController(text: c.description ?? ''),
    };
    await _editSheet(
      context,
      ref,
      title: 'Modifier l\'entreprise',
      fields: [
        _FieldDef('industry', 'Secteur', Icons.business_outlined),
        _FieldDef('location', 'Localisation', Icons.location_on_outlined),
        _FieldDef('description', 'Description', Icons.info_outline, maxLines: 4),
      ],
      controllers: controllers,
      onSave: () {
        return ref.read(profileProvider.notifier).updateCompany({
          'industry': controllers['industry']!.text.trim(),
          'location': controllers['location']!.text.trim(),
          'description': controllers['description']!.text.trim(),
        });
      },
    );
  }

  Future<void> _editSheet(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<_FieldDef> fields,
    required Map<String, TextEditingController> controllers,
    required Future<String?> Function() onSave,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        bool saving = false;
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            final theme = Theme.of(sheetContext);
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 8,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...fields.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: controllers[f.key],
                            maxLines: f.maxLines,
                            keyboardType: f.number ? TextInputType.number : TextInputType.text,
                            decoration: InputDecoration(
                              labelText: f.label,
                              prefixIcon: Icon(f.icon),
                            ),
                          ),
                        )),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setSheet(() => saving = true);
                              final err = await onSave();
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(err ?? 'Profil mis à jour ✅'),
                                    backgroundColor:
                                        err != null ? Theme.of(context).colorScheme.error : null,
                                  ),
                                );
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FieldDef {
  final String key;
  final String label;
  final IconData icon;
  final int maxLines;
  final bool number;
  _FieldDef(this.key, this.label, this.icon, {this.maxLines = 1, this.number = false});
}
