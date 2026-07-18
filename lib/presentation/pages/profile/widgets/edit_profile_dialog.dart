// lib/presentation/pages/profile/widgets/edit_profile_dialog.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/models/profile/profile_model.dart';
import '../../../providers/profile/profile_provider.dart';
import 'profile_theme.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  final ProfileModel profile;

  const EditProfileDialog({super.key, required this.profile});

  @override
  ConsumerState<EditProfileDialog> createState() =>
      _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  XFile? _pickedImage;
  Uint8List? _webImageBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController =
        TextEditingController(text: widget.profile.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // ✅ Always read bytes — needed on web, useful on native
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImage = image;
          _webImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Pick the right method based on platform
    final success = await ref
        .read(profileNotifierProvider.notifier)
        .updateProfileWithPhoto(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          // Web: send bytes
          photoBytes: kIsWeb ? _webImageBytes : null,
          photoFileName: _pickedImage?.name,
          // Native: send path
          photoFilePath: kIsWeb ? null : _pickedImage?.path,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      final error = ref.read(profileNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Update failed'),
          backgroundColor: ProfileTokens.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  ImageProvider? _getAvatarImage() {
    if (_pickedImage != null) {
      // ✅ Use bytes for both web AND native (simpler + safer)
      if (_webImageBytes != null) {
        return MemoryImage(_webImageBytes!);
      } else if (!kIsWeb) {
        return FileImage(File(_pickedImage!.path));
      }
    }
    if (widget.profile.profilePhotoUrl != null) {
      return NetworkImage(widget.profile.profilePhotoUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider);
    final isUpdating = state.isUpdating;
    final avatarImage = _getAvatarImage();

    // The dialog is pushed from a context above the page's Theme override,
    // so it re-applies the light theme itself. Without this the text fields
    // and selection handles fall back to the app's dark root theme.
    return Theme(
      data: buildProfileTheme(context),
      child: Dialog(
        backgroundColor: ProfileTokens.card,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ProfileTokens.radius),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isUpdating),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: ProfileTokens.divider,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPhotoPicker(avatarImage, isUpdating),
                        const SizedBox(height: 24),
                        _buildField(
                          controller: _nameController,
                          label: 'Full name',
                          icon: Icons.person_outline,
                          enabled: !isUpdating,
                          textInputAction: TextInputAction.next,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          enabled: !isUpdating,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(v.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _phoneController,
                          label: 'Phone',
                          hint: 'Optional',
                          icon: Icons.phone_outlined,
                          enabled: !isUpdating,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                  _buildActions(isUpdating),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader(bool isUpdating) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Edit profile',
              style: TextStyle(
                color: ProfileTokens.text,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: ProfileTokens.textMuted,
            tooltip: 'Close',
            onPressed:
                isUpdating ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  // ─── Photo picker ────────────────────────────────────────────────────
  Widget _buildPhotoPicker(ImageProvider? avatarImage, bool isUpdating) {
    final initial = widget.profile.name.isNotEmpty
        ? widget.profile.name[0].toUpperCase()
        : '?';

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ProfileTokens.border),
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: ProfileTokens.brandSubtle,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 32,
                            color: ProfileTokens.brandText,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: ProfileTokens.brand,
                  shape: const CircleBorder(
                    side: BorderSide(color: ProfileTokens.card, width: 3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: isUpdating ? null : _pickImage,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: isUpdating ? null : _pickImage,
            style: TextButton.styleFrom(
              foregroundColor: ProfileTokens.brandText,
              minimumSize: const Size(0, ProfileTokens.minTouchTarget),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(
              _pickedImage != null ? 'Change photo' : 'Upload photo',
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────
  Widget _buildActions(bool isUpdating) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed:
                isUpdating ? null : () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: ProfileTokens.textMuted,
              minimumSize: const Size(0, ProfileTokens.minTouchTarget),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ProfileTokens.radiusSm),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: isUpdating ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: ProfileTokens.brand,
              foregroundColor: Colors.white,
              disabledBackgroundColor: ProfileTokens.brand,
              disabledForegroundColor: Colors.white,
              minimumSize: const Size(0, ProfileTokens.minTouchTarget),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ProfileTokens.radiusSm),
              ),
            ),
            // Keeps the button's width stable while saving so the row
            // doesn't jump when the spinner swaps in.
            child: isUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }

  // ─── Field ───────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool enabled = true,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(ProfileTokens.radiusSm),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ProfileTokens.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          enabled: enabled,
          cursorColor: ProfileTokens.brand,
          style: const TextStyle(
            color: ProfileTokens.text,
            fontSize: 14.5,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: ProfileTokens.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, color: ProfileTokens.textMuted, size: 19),
            filled: true,
            fillColor: enabled ? ProfileTokens.card : ProfileTokens.subtle,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: border(ProfileTokens.border),
            enabledBorder: border(ProfileTokens.border),
            disabledBorder: border(ProfileTokens.border),
            focusedBorder: border(ProfileTokens.brand, 1.6),
            errorBorder: border(ProfileTokens.danger),
            focusedErrorBorder: border(ProfileTokens.danger, 1.6),
            errorStyle: const TextStyle(
              color: ProfileTokens.danger,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
