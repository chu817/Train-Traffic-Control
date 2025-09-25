import 'package:flutter/material.dart';

class StationDropdown extends StatefulWidget {
  final String? initialStation;
  final ValueChanged<String> onChanged;

  const StationDropdown({super.key, this.initialStation, required this.onChanged});

  @override
  State<StationDropdown> createState() => _StationDropdownState();
}

class _StationDropdownState extends State<StationDropdown> {
  final TextEditingController _controller = TextEditingController();
  String? _selected;

  static const List<String> _stations = [
    'Mumbai Central',
    'Mumbai CSMT',
    'Madurai',
    'Mangalore Central',
    'Mangalore Junction',
    'Mysuru',
    'Mahabubnagar',
    'Maharajpur',
    'Mathura Junction',
    'Meerut City',
    'Chennai Central',
    'Chennai Egmore',
    'Delhi Junction',
    'New Delhi',
    'Howrah Junction',
    'Sealdah',
    'Kolkata',
    'Kanpur Central',
    'Varanasi Junction',
    'Lucknow NR',
    'Jaipur',
    'Jodhpur',
    'Ahmedabad Junction',
    'Surat',
    'Pune Junction',
    'Nagpur',
    'Bengaluru City',
    'Yesvantpur Junction',
    'Hyderabad Deccan',
    'Secunderabad Junction',
    'Guwahati',
    'Patna Junction',
    'Bhopal Junction',
    'Indore Junction',
    'Coimbatore Junction',
    'Kochi Ernakulam',
    'Thiruvananthapuram Central',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialStation;
    if (_selected != null) _controller.text = _selected!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _selected ?? ''),
      optionsBuilder: (TextEditingValue value) {
        final q = value.text.trim();
        if (q.isEmpty) return _stations;
        return _stations.where((s) => s.toLowerCase().startsWith(q.toLowerCase()));
      },
      displayStringForOption: (s) => s,
      onSelected: (s) {
        setState(() {
          _selected = s;
          _controller.text = s;
        });
        widget.onChanged(s);
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        // Keep controller in sync with initial value
        if ((_selected ?? '').isNotEmpty && textEditingController.text.isEmpty) {
          textEditingController.text = _selected!;
        }
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Station',
            prefixIcon: Icon(Icons.train, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final opts = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, minWidth: 280),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: opts.length,
                itemBuilder: (context, index) {
                  final s = opts[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.train),
                    title: Text(s),
                    onTap: () => onSelected(s),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}


