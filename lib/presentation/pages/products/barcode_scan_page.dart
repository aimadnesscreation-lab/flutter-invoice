import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:invoice_pro/core/di/providers.dart';

class BarcodeScanPage extends ConsumerStatefulWidget {
  const BarcodeScanPage({super.key});

  @override
  ConsumerState<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends ConsumerState<BarcodeScanPage> {
  MobileScannerController? _controller;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessId = ref.watch(activeBusinessProvider)?.id ?? 'default';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller?.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => _controller?.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_hasScanned) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final barcode = barcodes.first.rawValue;
              if (barcode == null || barcode.isEmpty) return;

              _hasScanned = true;
              _lookupProduct(barcode, businessId);
            },
          ),
          // Scanning overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Instruction text
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Point camera at a barcode',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _lookupProduct(String barcode, String businessId) async {
    try {
      final product = await ref.read(productRepositoryProvider).getProductByBarcode(barcode, businessId);
      if (!mounted) return;

      if (product != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Product Found'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('SKU: ${product.sku ?? "N/A"}'),
                Text('Price: \$${product.sellingPrice.toStringAsFixed(2)}'),
                Text('Stock: ${product.quantity.toInt()} ${product.unit}'),
                if (product.isLowStock)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('LOW STOCK', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _hasScanned = false;
                },
                child: const Text('Scan Again'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No product found with barcode: $barcode'),
            action: SnackBarAction(label: 'Scan Again', onPressed: () => _hasScanned = false),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        _hasScanned = false;
      }
    }
  }
}
