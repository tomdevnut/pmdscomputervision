
import 'package:flutter/material.dart';

// Creo la schermata di aggiunta scan come statefulwidget per gestire lo stato (campi, caricamento)
class AddScanPage extends StatefulWidget {
  const AddScanPage({super.key});

  @override
  State<AddScanPage> createState() => _AddScanPageState();
}

class _AddScanPageState extends State<AddScanPage> {
   // creo una chiave globale per validare il form dello scan
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // definisco un controller per ciascun campo del form per modificarlo
  final TextEditingController _scanIdCtrl = TextEditingController();
  final TextEditingController _stepIdCtrl = TextEditingController();
  final TextEditingController _objectTypeCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();

    // variabile che tiene traccia dello stato di caricamento - fase salvataggio o caricamento avvenuto
  bool _saving = false;

  // libero la memoria dei controller quando la pagina viene chiusa con next
  @override
  void dispose() {
    _scanIdCtrl.dispose();
    _stepIdCtrl.dispose();
    _objectTypeCtrl.dispose();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // creo la funzione _onNext
  Future<void> _onNext() async {
    // validazione form
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    // payload con i dati inseriti dall'utente
    try {
      final payload = {
        'scanId': _scanIdCtrl.text.trim(),
        'stepId': _stepIdCtrl.text.trim(),
        'objectType': _objectTypeCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'ready',
      };

      if (!mounted) return;

      // messaggio di conferma 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan data saved')),
      );

      // permette di tornare alla pagina precedente passando i dati inseriti
      Navigator.of(context).pop(payload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar( // restituisce i dati a chi ha aperto la pagina
        SnackBar(content: Text('Errore: $e')), // in caso di errore mostra una snackbar rossa
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0F0F0F);
    const card = Color(0xFF161616);
    const field = Color(0xFF2A2421);
    const pill = Color(0xFFF3E1D6);

    return Scaffold( // dà la struttura base della pagina
      backgroundColor: bg,

      // definisco i campi di appBar
      appBar: AppBar(
        backgroundColor: bg,
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          // icona fotocamera a sx per effettuare la scansione con il lidar
          icon: const Icon(Icons.camera_alt_outlined),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            // icona immagine a dx per accedere alla galleria e scegliere un file già esistenteo
            icon: const Icon(Icons.image_outlined),
            onPressed: () {},
          ),
        ],
        title: const Text('New Scan'),
      ),

      // creazione card + form (ogni campo ha una propria validazione)
      body: SafeArea(
        child: ListView( // listview con padding per creare una pagina scrollabile
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container( 
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0x22FFFFFF)),
              ),

              // definisco il contenuto della card
              child: Form(
                key: _formKey, // collegamento del form a formkey per la validazione
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Model',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter details about your object',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),

                    // ogni campo ha: etichetta, spazietura, textformfield con validazione required
                    const SizedBox(height: 20),
                    _label('Scan ID'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _scanIdCtrl,
                      decoration: _decoration('Value', field),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    _label('Step ID'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _stepIdCtrl,
                      decoration: _decoration('Value', field),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    _label('Object Type'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _objectTypeCtrl,
                      decoration: _decoration('Value', field),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    _label('Name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _decoration('Value', field),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    _label('Description'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionCtrl,
                      maxLines: 6, // è un campo multilinea
                      decoration: _decoration('', field),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),

            // bottone next
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: pill,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),

                // se _saving è true viene disabilitato il tap
                onPressed: _saving ? null : _onNext,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // gestione di etichette
  Widget _label(String text) => Text(
        text, // testo usato sopra ogni campo
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      );

  // stile uniforme per tutti i TextFormField
  InputDecoration _decoration(String hint, Color fill) {
    return InputDecoration(
      hintText: hint.isEmpty ? null : hint,
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x66FFFFFF)),
      ),
    );
  }
}
