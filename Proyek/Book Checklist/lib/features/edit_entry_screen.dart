import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/utils/image_storage.dart';
import '../core/widgets/media_cover.dart';
import '../domain/media_entry.dart';
import '../providers/app_providers.dart';

class EditEntryScreen extends ConsumerStatefulWidget {
  const EditEntryScreen({super.key, required this.type, this.entry});

  final MediaType type;
  final MediaEntry? entry;

  @override
  ConsumerState<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends ConsumerState<EditEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _creator;
  late final TextEditingController _imageUrl;
  late final TextEditingController _genre;
  late final TextEditingController _year;
  late final TextEditingController _totalPages;
  late final TextEditingController _pagesRead;
  late final TextEditingController _duration;
  late final TextEditingController _synopsis;
  late final TextEditingController _seasons;
  late final TextEditingController _episodes;
  late final TextEditingController _currentSeason;
  late final TextEditingController _currentEpisode;
  late final TextEditingController _rating;
  late final TextEditingController _notes;
  late MediaStatus _status;
  String? _imagePath;
  DateTime? _startedAt;
  DateTime? _completedAt;
  bool _saving = false;

  MediaEntry? get _entry => widget.entry;

  @override
  void initState() {
    super.initState();
    final entry = _entry;
    _title = TextEditingController(text: entry?.title ?? '');
    _creator = TextEditingController(text: entry?.creator ?? '');
    _imageUrl = TextEditingController(text: entry?.imageUrl ?? '');
    _genre = TextEditingController(text: entry?.genre ?? '');
    _year = TextEditingController(text: entry?.releaseYear?.toString() ?? '');
    _totalPages = TextEditingController(
      text: entry == null || entry.totalPages == 0 ? '' : '${entry.totalPages}',
    );
    _pagesRead = TextEditingController(
      text: entry == null || entry.pagesRead == 0 ? '' : '${entry.pagesRead}',
    );
    _duration = TextEditingController(
      text: entry == null || entry.durationMinutes == 0
          ? ''
          : '${entry.durationMinutes}',
    );
    _synopsis = TextEditingController(text: entry?.synopsis ?? '');
    _seasons = TextEditingController(
      text: entry == null || entry.totalSeasons == 0
          ? ''
          : '${entry.totalSeasons}',
    );
    _episodes = TextEditingController(
      text: entry == null || entry.totalEpisodes == 0
          ? ''
          : '${entry.totalEpisodes}',
    );
    _currentSeason = TextEditingController(
      text: '${entry?.currentSeason ?? 1}',
    );
    _currentEpisode = TextEditingController(
      text: entry == null || entry.currentEpisode == 0
          ? ''
          : '${entry.currentEpisode}',
    );
    _rating = TextEditingController(
      text: entry?.rating == null ? '' : '${entry!.rating}',
    );
    _notes = TextEditingController(text: entry?.notes ?? '');
    _status = entry?.status ?? statusesFor(widget.type).first;
    _imagePath = entry?.imagePath;
    _startedAt = entry?.startedAt;
    _completedAt = entry?.completedAt;
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _creator,
      _imageUrl,
      _genre,
      _year,
      _totalPages,
      _pagesRead,
      _duration,
      _synopsis,
      _seasons,
      _episodes,
      _currentSeason,
      _currentEpisode,
      _rating,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _number(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  String? _optionalNumber(
    String? value, {
    int? min,
    int? max,
    bool decimal = false,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = decimal
        ? double.tryParse(value.trim())
        : int.tryParse(value.trim())?.toDouble();
    if (parsed == null) return 'Enter a valid number';
    if (min != null && parsed < min) return 'Must be at least $min';
    if (max != null && parsed > max) return 'Must be $max or less';
    return null;
  }

  Future<void> _pickCover() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 86,
        maxWidth: 1800,
      );
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      final filename = 'cover_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final destination = await persistCover(
        bytes,
        filename,
        mimeType: image.mimeType ?? 'image/jpeg',
      );
      if (mounted) setState(() => _imagePath = destination);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not add image: $error')));
      }
    }
  }

  Future<DateTime?> _chooseDate(DateTime? current) async => showDatePicker(
    context: context,
    initialDate: current ?? DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime.now().add(const Duration(days: 3660)),
  );

  Future<void> _pickStartedDate() async {
    final selected = await _chooseDate(_startedAt);
    if (selected != null && mounted) setState(() => _startedAt = selected);
  }

  Future<void> _pickCompletedDate() async {
    final selected = await _chooseDate(_completedAt);
    if (selected != null && mounted) setState(() => _completedAt = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final started =
        _startedAt ??
        ([_status].any(
              (status) =>
                  status == MediaStatus.currentlyReading ||
                  status == MediaStatus.watching,
            )
            ? now
            : null);
    final completed = _status == MediaStatus.completed
        ? (_completedAt ?? now)
        : _completedAt;
    final entry = MediaEntry(
      id: _entry?.id,
      type: widget.type,
      title: _title.text.trim(),
      creator: _creator.text.trim(),
      imagePath: _imagePath,
      imageUrl: _imageUrl.text.trim(),
      genre: _genre.text.trim(),
      releaseYear: int.tryParse(_year.text.trim()),
      totalPages: widget.type == MediaType.book ? _number(_totalPages) : 0,
      pagesRead: widget.type == MediaType.book ? _number(_pagesRead) : 0,
      durationMinutes: widget.type == MediaType.movie ? _number(_duration) : 0,
      synopsis: _synopsis.text.trim(),
      totalSeasons: widget.type == MediaType.series ? _number(_seasons) : 0,
      totalEpisodes: widget.type == MediaType.series ? _number(_episodes) : 0,
      currentSeason: widget.type == MediaType.series
          ? _number(_currentSeason).clamp(1, 999)
          : 1,
      currentEpisode: widget.type == MediaType.series
          ? _number(_currentEpisode)
          : 0,
      status: _status,
      rating: double.tryParse(_rating.text.trim()),
      notes: _notes.text.trim(),
      startedAt: started,
      completedAt: completed,
      createdAt: _entry?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await ref.read(mediaEntriesProvider.notifier).save(entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _entry == null
                ? '${widget.type.label} added to your shelf'
                : 'Changes saved',
          ),
        ),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBook = widget.type == MediaType.book;
    final isMovie = widget.type == MediaType.movie;
    final title = _entry == null
        ? 'Add ${widget.type.label.toLowerCase()}'
        : 'Edit ${widget.type.label.toLowerCase()}';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _sectionLabel(context, 'The basics'),
              const SizedBox(height: 12),
              _field(
                _title,
                'Title',
                required: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              _field(_creator, isBook ? 'Author' : 'Director / creator'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _field(_genre, 'Genre')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _year,
                      'Release year',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => _optionalNumber(
                        value,
                        min: 1800,
                        max: DateTime.now().year + 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _sectionLabel(context, 'Cover or poster'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MediaCover(
                    type: widget.type,
                    imagePath: _imagePath,
                    imageUrl: _imageUrl.text,
                    width: 76,
                    height: 100,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pickCover,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Choose from photos'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _field(
                          _imageUrl,
                          'Or paste an image URL',
                          keyboardType: TextInputType.url,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _sectionLabel(context, 'Your tracking'),
              const SizedBox(height: 12),
              DropdownButtonFormField<MediaStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: statusesFor(widget.type)
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                    )
                    .toList(),
                onChanged: (status) {
                  if (status != null) setState(() => _status = status);
                },
              ),
              const SizedBox(height: 12),
              if (isBook) ...[
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _totalPages,
                        'Total pages',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) => _optionalNumber(value, min: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _pagesRead,
                        'Pages read',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          final error = _optionalNumber(value, min: 0);
                          if (error != null) return error;
                          final read = int.tryParse(value ?? '') ?? 0;
                          final total = int.tryParse(_totalPages.text) ?? 0;
                          return total > 0 && read > total
                              ? 'Cannot exceed total pages'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
              ] else if (isMovie) ...[
                _field(
                  _duration,
                  'Duration in minutes',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => _optionalNumber(value, min: 1),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _seasons,
                        'Total seasons',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) => _optionalNumber(value, min: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _episodes,
                        'Total episodes',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) => _optionalNumber(value, min: 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _currentSeason,
                        'Current season',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) => _optionalNumber(value, min: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _currentEpisode,
                        'Episode watched',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          final error = _optionalNumber(value, min: 0);
                          if (error != null) return error;
                          final watched = int.tryParse(value ?? '') ?? 0;
                          final total = int.tryParse(_episodes.text) ?? 0;
                          return total > 0 && watched > total
                              ? 'Cannot exceed total episodes'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _field(
                _rating,
                'Your rating (0–5)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (value) =>
                    _optionalNumber(value, min: 0, max: 5, decimal: true),
              ),
              const SizedBox(height: 22),
              _sectionLabel(context, 'Dates & notes'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _dateButton('Started', _startedAt, _pickStartedDate),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateButton(
                      'Finished',
                      _completedAt,
                      _pickCompletedDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                _synopsis,
                'Synopsis',
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              _field(
                _notes,
                'Personal notes',
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving…' : 'Save to shelf'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      letterSpacing: 1.1,
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    inputFormatters: inputFormatters,
    onChanged: onChanged,
    validator:
        validator ??
        (required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'Please enter a title'
                  : null
            : null),
    decoration: InputDecoration(
      labelText: label,
      suffixText: required ? '*' : null,
      alignLabelWithHint: maxLines > 1,
    ),
  );

  Widget _dateButton(String label, DateTime? date, VoidCallback onPressed) =>
      OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.calendar_month_rounded, size: 18),
        label: Text(
          date == null
              ? label
              : '$label · ${date.day}/${date.month}/${date.year}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
}
