import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../Presenters/AuthPresenter.dart';
import '../widgets/profile_avatar.dart';

enum _ManageAccountAction { username, password }

Uint8List _optimizeProfileImage(Uint8List bytes) {
  final decodedImage = img.decodeImage(bytes);

  if (decodedImage == null) {
    throw StateError('The selected image could not be decoded.');
  }

  final resizedImage = img.copyResizeCropSquare(decodedImage, size: 512);

  return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 70));
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _backgroundColor = Color.fromARGB(255, 247, 231, 206);
  static const _primaryColor = Color(0xFF1F5DA8);
  static const _maxImageSizeBytes = 5 * 1024 * 1024;
  static const _maxEncodedImageLength = 1500000;

  final _authPresenter = AuthPresenter();
  final _database = FirebaseDatabase.instance;

  bool _isUploading = false;
  bool _isPreparingImage = false;
  bool _isRemovingImage = false;
  bool _isDeletingAccount = false;
  double _uploadProgress = 0;

  Future<void> _changeProfileImage(User user) async {
    List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(type: FileType.image);
    } catch (error) {
      if (mounted) {
        _showMessage('Could not open the image picker: $error');
      }
      return;
    }

    if (files.isEmpty || !mounted) return;

    final file = files.first;
    final int? size;
    try {
      size = await file.length();
    } catch (error) {
      if (mounted) {
        _showMessage('Could not read the selected image: $error');
      }
      return;
    }

    if (!mounted) return;
    if (size == null || size == 0) {
      _showMessage('Could not read the selected image.');
      return;
    }

    if (size > _maxImageSizeBytes) {
      _showMessage('Choose an image smaller than 5 MB.');
      return;
    }

    late final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (error) {
      if (mounted) {
        _showMessage('Could not read the selected image: $error');
      }
      return;
    }

    if (!mounted) return;
    if (bytes.isEmpty) {
      _showMessage('Could not read the selected image.');
      return;
    }

    setState(() {
      _isUploading = true;
      _isPreparingImage = true;
      _uploadProgress = 0;
    });

    try {
      final optimizedImage = _optimizeProfileImage(bytes);
      final encodedImage = base64Encode(optimizedImage);

      if (encodedImage.length > _maxEncodedImageLength) {
        throw StateError(
          'The compressed image is too large. Please choose another image.',
        );
      }

      if (!mounted) return;

      setState(() {
        _isPreparingImage = false;
        _uploadProgress = 0.5;
      });

      await _database.ref('profileImages/${user.uid}').set({
        'imageData': encodedImage,
        'contentType': 'image/jpeg',
      });

      if (mounted) {
        setState(() => _uploadProgress = 1);
        _showMessage('Profile photo updated.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Could not update profile photo: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isPreparingImage = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  Future<void> _removeProfileImage(User user) async {
    setState(() => _isRemovingImage = true);

    try {
      await _database.ref('profileImages/${user.uid}').remove();

      if (mounted) {
        _showMessage('Profile picture removed.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Could not remove profile picture: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isRemovingImage = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signOut() async {
    try {
      await _authPresenter.signOut();

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Could not sign out: $error');
      }
    }
  }

  Future<void> _deleteAccount(User user) async {
    final passwordController = TextEditingController();
    String? validationError;

    try {
      final password = await showDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFFFFF9EF),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Delete account?',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This permanently deletes your account and cannot be undone. '
                  'Enter your password to confirm.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  autofocus: true,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    errorText: validationError,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _primaryColor.withValues(alpha: 0.25),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: _primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (validationError != null) {
                      setDialogState(() => validationError = null);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: _primaryColor),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (passwordController.text.isEmpty) {
                    setDialogState(
                      () => validationError = 'Enter your current password.',
                    );
                    return;
                  }

                  Navigator.pop(context, passwordController.text);
                },
                child: const Text('Delete account'),
              ),
            ],
          ),
        ),
      );

      if (password == null || !mounted) return;

      setState(() => _isDeletingAccount = true);

      await _authPresenter.reauthenticate(password);
      await _database.ref('profileImages/${user.uid}').remove();
      await _authPresenter.deleteAccount();

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      Navigator.popUntil(context, (route) => route.isFirst);

      messenger.showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Could not delete account: $error');
      }
    } finally {
      passwordController.dispose();

      if (mounted) {
        setState(() => _isDeletingAccount = false);
      }
    }
  }

  Future<void> _selectManageAction(
    _ManageAccountAction action,
    User user,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _AccountChangeScreen(
          action: action,
          user: user,
          authPresenter: _authPresenter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: _backgroundColor,
        actions: [
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department, color: Color(0xFFE76F00)),
                  SizedBox(width: 8),
                  Text('Streak', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: StreamBuilder<User?>(
        stream: _authPresenter.userChanges(),
        initialData: _authPresenter.currentUser,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load your profile. Please try again.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          if (user == null) {
            return const Center(
              child: Text('Please sign in to view your profile.'),
            );
          }

          return StreamBuilder<DatabaseEvent>(
            stream: _database.ref('profileImages/${user.uid}').onValue,
            builder: (context, imageSnapshot) {
              if (imageSnapshot.hasError) {
                return const Center(
                  child: Text('Could not load your profile picture.'),
                );
              }

              final profileData = imageSnapshot.data?.snapshot.value;
              final hasProfileImage =
                  profileData is Map && profileData['imageData'] is String;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProfileAvatar(profileData: profileData),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _isUploading || _isRemovingImage
                            ? null
                            : () => _changeProfileImage(user),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(
                          _isUploading
                              ? _isPreparingImage
                                    ? 'Preparing picture...'
                                    : 'Saving picture...'
                              : 'Change profile picture',
                        ),
                      ),
                      if (hasProfileImage) ...[
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: _isUploading || _isRemovingImage
                              ? null
                              : () => _removeProfileImage(user),
                          icon: _isRemovingImage
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.restore),
                          label: Text(
                            _isRemovingImage ? 'Removing...' : 'Remove photo',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                          ),
                        ),
                      ],
                      if (_isUploading) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 220,
                          child: LinearProgressIndicator(
                            value: _isPreparingImage ? null : _uploadProgress,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isDeletingAccount
                                    ? null
                                    : () => _deleteAccount(user),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text(
                                  'Delete account',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PopupMenuButton<_ManageAccountAction>(
                                enabled: !_isDeletingAccount,
                                onSelected: (action) async {
                                  await _selectManageAction(action, user);
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: _ManageAccountAction.username,
                                    child: Text('Change username'),
                                  ),
                                  PopupMenuItem(
                                    value: _ManageAccountAction.password,
                                    child: Text('Change password'),
                                  ),
                                ],
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.manage_accounts_outlined,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Manage account',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.history),
                            label: const Text('History'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryColor,
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                      ),
                      if (_isDeletingAccount) ...[
                        const SizedBox(height: 12),
                        const CircularProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AccountChangeScreen extends StatefulWidget {
  const _AccountChangeScreen({
    required this.action,
    required this.user,
    required this.authPresenter,
  });

  final _ManageAccountAction action;
  final User user;
  final AuthPresenter authPresenter;

  @override
  State<_AccountChangeScreen> createState() => _AccountChangeScreenState();
}

class _AccountChangeScreenState extends State<_AccountChangeScreen> {
  static const _backgroundColor = Color.fromARGB(255, 247, 231, 206);
  static const _primaryColor = Color(0xFF1F5DA8);

  late final TextEditingController _usernameController;
  final _newEmailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  bool get _isUsernameAction => widget.action == _ManageAccountAction.username;
  bool get _hasExistingUsername =>
      widget.user.displayName?.trim().isNotEmpty ?? false;
  bool get _isChangingEmail {
    final newEmail = _newEmailController.text.trim();
    return newEmail.isNotEmpty &&
        newEmail.toLowerCase() != widget.user.email?.toLowerCase();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.user.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isUsernameAction) {
      final username = _usernameController.text.trim();
      if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{2,19}$').hasMatch(username)) {
        setState(
          () => _errorMessage =
              'Use 3–20 letters, numbers, periods, underscores, or hyphens.',
        );
        return;
      }
      if (_isChangingEmail && !_isValidEmail(_newEmailController.text)) {
        setState(() => _errorMessage = 'Enter a valid new email address.');
        return;
      }
      if (_isChangingEmail && _currentPasswordController.text.isEmpty) {
        setState(
          () => _errorMessage =
              'Enter your current password to change your email.',
        );
        return;
      }
    } else {
      if (_currentPasswordController.text.isEmpty) {
        setState(() => _errorMessage = 'Enter your current password.');
        return;
      }
      if (_newPasswordController.text.length < 6) {
        setState(
          () => _errorMessage = 'New password must be at least 6 characters.',
        );
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        setState(() => _errorMessage = 'The passwords do not match.');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_isUsernameAction) {
        await widget.authPresenter.updateUsernameAndEmail(
          username: _usernameController.text.trim(),
          newEmail: _isChangingEmail ? _newEmailController.text.trim() : null,
          currentPassword: _isChangingEmail
              ? _currentPasswordController.text
              : null,
        );
      } else {
        await widget.authPresenter.reauthenticate(
          _currentPasswordController.text,
        );
        await widget.authPresenter.updatePassword(_newPasswordController.text);
      }

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final message = _isUsernameAction
          ? _isChangingEmail
                ? 'Username updated. Check your new email for verification.'
                : 'Username updated.'
          : 'Password updated.';
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) {
        setState(() {
          final details = error.toString().replaceFirst(
            RegExp(r'^Bad state:\s*'),
            '',
          );
          _errorMessage = _isUsernameAction
              ? 'Could not save your username: $details'
              : 'Could not update your password: $details';
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: BackButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
          ),
          title: Text(
            _isUsernameAction
                ? _hasExistingUsername
                      ? 'Change username'
                      : 'Create username'
                : 'Change password',
          ),
          backgroundColor: _backgroundColor,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isUsernameAction
                              ? _hasExistingUsername
                                    ? 'Choose a new username'
                                    : 'Create your username'
                              : 'Choose a new password',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_isUsernameAction) ...[
                          if (widget.user.email != null) ...[
                            Text(
                              'Account email: ${widget.user.email}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextField(
                            controller: _usernameController,
                            autofocus: true,
                            textCapitalization: TextCapitalization.none,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              helperText:
                                  'Use 3–20 letters, numbers, ., _ or -',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _newEmailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'New email (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (_isChangingEmail) ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _currentPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Current password',
                                helperText:
                                    'Required to confirm an email change.',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ] else ...[
                          TextField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Current password',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'New password',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm new password',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isSaving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save changes'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
