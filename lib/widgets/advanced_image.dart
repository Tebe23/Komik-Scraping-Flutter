import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

class AdvancedImage extends StatelessWidget {
  final String imageUrl;
  final double? height;

  const AdvancedImage({
    Key? key,
    required this.imageUrl,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showZoomableImage(context),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        fit: BoxFit.contain,
        placeholder: (context, url) => AspectRatio(
          aspectRatio: 2/3,
          child: Container(
            color: Colors.grey[200],
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        errorWidget: (context, url, error) => AspectRatio(
          aspectRatio: 2/3,
          child: Container(
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64),
                Text('Failed to load image'),
                ElevatedButton(
                  onPressed: () => CachedNetworkImage.evictFromCache(imageUrl),
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showZoomableImage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              PhotoView(
                imageProvider: CachedNetworkImageProvider(imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
