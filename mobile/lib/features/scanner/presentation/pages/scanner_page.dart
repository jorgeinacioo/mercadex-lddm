import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/core/theme/app_colors.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';
import 'package:mercadex/features/products/domain/product_summary.dart';
import 'package:mercadex/features/products/presentation/providers/products_providers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Reads a product barcode with the camera (or typed by hand) and opens the
/// product it belongs to.
class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key, this.enableCamera = true});

  /// Widget tests run without a camera.
  final bool enableCamera;

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  MobileScannerController? _controller;
  var _looking = false;
  var _leaving = false;
  var _overlayOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableCamera) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code128,
        ],
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (code.isEmpty || _looking || _overlayOpen) return;
    HapticFeedback.mediumImpact();
    _lookUp(code);
  }

  Future<void> _lookUp(String code) async {
    if (_looking) return;
    setState(() => _looking = true);
    await _controller?.pause();

    ProductSummary? product;
    Object? failure;
    try {
      product = await ref.read(productsRepositoryProvider).findByBarcode(code);
    } catch (error) {
      failure = error;
    }
    if (!mounted) return;
    if (product != null) {
      _leaving = true;
      context.pushReplacement('/product/${product.id}');
      return;
    }

    setState(() => _looking = false);
    if (failure == null) {
      await _showResult(
        title: 'Produto não encontrado',
        message:
            'O código $code ainda não está no Mercadex. '
            'Você pode procurar o produto pelo nome.',
        icon: Icons.search_off_rounded,
      );
    } else {
      await _showResult(
        title: 'Não foi possível consultar o código',
        message: friendlyError(failure),
        icon: Icons.cloud_off_outlined,
      );
    }
    if (mounted && !_leaving) await _controller?.start();
  }

  Future<void> _showResult({
    required String title,
    required String message,
    required IconData icon,
  }) async {
    _overlayOpen = true;
    final searchByName = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final text = Theme.of(context).textTheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: text.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Escanear novamente'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Buscar pelo nome'),
                ),
              ],
            ),
          ),
        );
      },
    );
    _overlayOpen = false;
    if (searchByName == true && mounted) {
      _leaving = true;
      context.pushReplacement('/search');
    }
  }

  Future<void> _typeCode() async {
    _overlayOpen = true;
    await _controller?.pause();
    if (!mounted) return;
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const _TypeCodeDialog(),
    );
    _overlayOpen = false;
    if (!mounted) return;
    if (code != null && code.isNotEmpty) {
      await _lookUp(code);
    } else {
      await _controller?.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final controller = _controller;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Escanear produto',
        actions: [
          if (controller != null)
            IconButton(
              tooltip: 'Lanterna',
              onPressed: controller.toggleTorch,
              icon: const Icon(Icons.flashlight_on_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: ColoredBox(
                      color: const Color(0xFF0B1410),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (controller != null)
                            Positioned.fill(
                              child: MobileScanner(
                                controller: controller,
                                onDetect: _onDetect,
                                errorBuilder: (context, error) =>
                                    _CameraUnavailable(error: error),
                              ),
                            )
                          else
                            const _CameraUnavailable(),
                          IgnorePointer(
                            child: Container(
                              width: 250,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.amber,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          if (_looking)
                            const Positioned.fill(
                              child: ColoredBox(
                                color: Color(0x88000000),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Aponte para o código de barras',
                style: text.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'O produto abre assim que o código for reconhecido.',
                style: text.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _looking ? null : _typeCode,
                icon: const Icon(Icons.keyboard_alt_outlined),
                label: const Text('Digitar o código'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({this.error});

  final MobileScannerException? error;

  @override
  Widget build(BuildContext context) {
    final message = switch (error?.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Permita o acesso à câmera nos Ajustes do aparelho para escanear.',
      _ => 'A câmera não está disponível neste aparelho. Digite o código.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white70,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCodeDialog extends StatefulWidget {
  const _TypeCodeDialog();

  @override
  State<_TypeCodeDialog> createState() => _TypeCodeDialogState();
}

class _TypeCodeDialogState extends State<_TypeCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Digitar código'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(14),
        ],
        decoration: const InputDecoration(
          hintText: 'Números abaixo do código de barras',
        ),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _confirm, child: const Text('Buscar')),
      ],
    );
  }
}
