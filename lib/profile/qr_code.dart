// qr_code_modal.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class QRCodeModal extends StatelessWidget {
  final String qrCodeUrl;

  QRCodeModal({required this.qrCodeUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFF45F67), width: 4), // Pinkish-red border around modal
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // QR Code with scanner corners
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: qrCodeUrl,
                  placeholder: (context, url) => CircularProgressIndicator(
                    color: Color(0xFFF45F67),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error, color: Color(0xFFF45F67)),
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
                // Scanner corners with thickness 4
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFF45F67), width: 4),
                        left: BorderSide(color: Color(0xFFF45F67), width: 4),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFF45F67), width: 4),
                        right: BorderSide(color: Color(0xFFF45F67), width: 4),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF45F67), width: 4),
                        left: BorderSide(color: Color(0xFFF45F67), width: 4),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF45F67), width: 4),
                        right: BorderSide(color: Color(0xFFF45F67), width: 4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            // Close Button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF45F67),
                shape: StadiumBorder(),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
