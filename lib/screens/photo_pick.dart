import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../services/strings.dart';
import '../theme/tokens.dart';
import '../widgets/motion.dart';

/// In-app photo grid backed by MediaStore. With "Select photos" (limited)
/// access this shows ONLY the photos the user approved — a clean, focused
/// picker instead of the whole gallery. Pops with the chosen photo's bytes.
class PhotoPickScreen extends StatefulWidget {
  const PhotoPickScreen({super.key});

  @override
  State<PhotoPickScreen> createState() => _PhotoPickScreenState();
}

class _PhotoPickScreenState extends State<PhotoPickScreen> {
  List<AssetEntity> _assets = const [];
  PermissionState? _perm;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;
    if (!perm.hasAccess) {
      setState(() {
        _perm = perm;
        _loading = false;
      });
      return;
    }
    final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image, onlyAll: true);
    final assets = paths.isEmpty
        ? const <AssetEntity>[]
        : await paths.first.getAssetListPaged(page: 0, size: 120);
    if (!mounted) return;
    setState(() {
      _perm = perm;
      _assets = assets;
      _loading = false;
    });
  }

  Future<void> _pick(AssetEntity a) async {
    final bytes = await a.originBytes;
    if (!mounted || bytes == null) return;
    Navigator.of(context).pop<Uint8List>(bytes);
  }

  /// Re-opens the system's limited-photos selection so the user can change
  /// which photos this app may see.
  Future<void> _manage() async {
    await PhotoManager.presentLimited();
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final limited = _perm == PermissionState.limited;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.pickFromPhotos),
        actions: [
          if (limited)
            IconButton(
              tooltip: S.managePhotos,
              onPressed: _manage,
              icon: const Icon(Icons.tune, size: 22),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_perm?.hasAccess != true)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(T.s6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(S.allowPhotosHint,
                            style: T.body.copyWith(color: c.inkMuted),
                            textAlign: TextAlign.center),
                        const SizedBox(height: T.s4),
                        FilledButton(
                            onPressed: () => PhotoManager.openSetting(),
                            child: Text(S.settings)),
                      ],
                    ),
                  ),
                )
              : _assets.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(T.s6),
                        child: Text(S.noPhotosYet,
                            style: T.body.copyWith(color: c.inkMuted),
                            textAlign: TextAlign.center),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(T.s3),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: T.s2,
                        crossAxisSpacing: T.s2,
                      ),
                      itemCount: _assets.length,
                      itemBuilder: (_, i) => _Thumb(
                          asset: _assets[i],
                          onTap: () => _pick(_assets[i])),
                    ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onTap;

  const _Thumb({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      label: S.packPhoto,
      child: Pressable(
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(T.rSm),
            child: FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(
                  const ThumbnailSize.square(360)),
              builder: (_, snap) => snap.data == null
                  ? ColoredBox(color: c.surface)
                  : Image.memory(snap.data!, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}
