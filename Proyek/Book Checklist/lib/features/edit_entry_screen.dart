import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/utils/image_storage.dart';
import '../core/widgets/media_cover.dart';
import '../core/widgets/rating_stars.dart';
import '../data/media_catalog_service.dart';
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
  late final TextEditingController _notes;
  late MediaStatus _status;
  double? _ratingValue;
  String? _imagePath;
  DateTime? _startedAt;
  DateTime? _completedAt;
  bool _saving = false;
  bool _searching = false;
  bool _catalogSearchCompleted = false;
  String? _catalogSearchError;
  List<MediaSearchResult> _catalogResults = const [];
  Timer? _catalogSearchDebounce;
  int _catalogSearchGeneration = 0;

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
    _ratingValue = entry?.rating;
    _notes = TextEditingController(text: entry?.notes ?? '');
    _status = entry?.status ?? statusesFor(widget.type).first;
    _imagePath = entry?.imagePath;
    _startedAt = entry?.startedAt;
    _completedAt = entry?.completedAt;
  }

  @override
  void dispose() {
    _catalogSearchDebounce?.cancel();
    _catalogSearchGeneration++;
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
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _number(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  String? _optionalNumber(String? value, {int? min, int? max}) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
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

  void _onTitleChanged(String value) {
    _catalogSearchDebounce?.cancel();
    final generation = ++_catalogSearchGeneration;
    final query = value.trim();
    setState(() {
      _searching = false;
      _catalogSearchCompleted = false;
      _catalogSearchError = null;
      _catalogResults = const [];
    });
    if (query.length < 2) return;

    _catalogSearchDebounce = Timer(const Duration(milliseconds: 450), () {
      _searchCatalog(query, generation);
    });
  }

  Future<void> _searchCatalog(String query, int generation) async {
    if (!mounted || generation != _catalogSearchGeneration) return;
    setState(() => _searching = true);
    try {
      final results = await ref
          .read(mediaCatalogProvider)
          .search(widget.type, query);
      if (!mounted || generation != _catalogSearchGeneration) return;
      setState(() {
        _catalogResults = results;
        _catalogSearchCompleted = true;
      });
    } catch (error) {
      if (!mounted || generation != _catalogSearchGeneration) return;
      setState(() {
        _catalogSearchError = 'Could not search the catalog: $error';
        _catalogSearchCompleted = true;
      });
    } finally {
      if (mounted && generation == _catalogSearchGeneration) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _selectCatalogResult(MediaSearchResult result) async {
    _catalogSearchDebounce?.cancel();
    final generation = ++_catalogSearchGeneration;
    setState(() {
      _catalogResults = const [];
      _catalogSearchCompleted = false;
      _catalogSearchError = null;
      _searching = false;
    });
    _applyCatalogResult(result);

    if (widget.type != MediaType.series || result.externalId == null) return;
    try {
      final details = await ref
          .read(mediaCatalogProvider)
          .loadSeriesDetails(result);
      if (!mounted || generation != _catalogSearchGeneration) return;
      setState(() {
        _seasons.text = _countText(details.totalSeasons);
        _episodes.text = _countText(details.totalEpisodes);
      });
    } catch (error) {
      if (mounted && generation == _catalogSearchGeneration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Series details were filled, but episode counts could not be loaded: $error',
            ),
          ),
        );
      }
    }
  }

  void _applyCatalogResult(MediaSearchResult result) {
    setState(() {
      _title.text = result.title;
      _creator.text = result.creator;
      _genre.text = result.genre;
      _year.text = result.releaseYear?.toString() ?? '';
      _imageUrl.text = result.imageUrl;
      _synopsis.text = result.synopsis;
      _totalPages.text = _countText(result.totalPages);
      _duration.text = _countText(result.durationMinutes);
      _seasons.text = _countText(result.totalSeasons);
      _episodes.text = _countText(result.totalEpisodes);
    });
  }

  Widget _catalogSuggestions(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ListTile(dense: true, title: Text('Suggestions')),
        for (
          var index = 0;
          index < _catalogResults.length && index < 5;
          index++
        ) ...[
          if (index > 0) const Divider(height: 1, indent: 16),
          _catalogResultTile(context, _catalogResults[index]),
        ],
      ],
    ),
  );

  Widget _catalogResultTile(BuildContext context, MediaSearchResult result) {
    final details = [
      if (result.creator.isNotEmpty) result.creator,
      if (result.releaseYear != null) '${result.releaseYear}',
    ].join(' · ');
    return ListTile(
      leading: const Icon(Icons.search_rounded),
      title: Text(result.title, maxLines: 1),
      subtitle: details.isEmpty ? null : Text(details, maxLines: 1),
      onTap: () {
        FocusScope.of(context).unfocus();
        _selectCatalogResult(result);
      },
    );
  }

  String _countText(int count) => count == 0 ? '' : '$count';

  void _save() {
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
      rating: _ratingValue,
      notes: _notes.text.trim(),
      startedAt: started,
      completedAt: completed,
      createdAt: _entry?.createdAt ?? now,
      updatedAt: now,
    );

    final messenger = ScaffoldMessenger.of(context);
    final saveFuture = ref.read(mediaEntriesProvider.notifier).save(entry);
    final successMessage = _entry == null
        ? '${widget.type.label} added to your shelf'
        : 'Changes saved';
    context.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Saving to your shelf…')),
    );
    unawaited(
      saveFuture
          .then<void>((_) {
            if (messenger.mounted) {
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(SnackBar(content: Text(successMessage)));
            }
          })
          .catchError((Object error) {
            if (messenger.mounted) {
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(content: Text('Could not save: $error')),
              );
            }
          }),
    );
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
                onChanged: _entry == null ? _onTitleChanged : null,
              ),
              if (_entry == null) ...[
                if (_searching)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (_catalogResults.isNotEmpty) _catalogSuggestions(context),
                if (_catalogSearchError case final error?)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (_catalogSearchCompleted &&
                    !_searching &&
                    _catalogResults.isEmpty &&
                    _catalogSearchError == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('No matching titles found.'),
                    ),
                  ),
              ],
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
              Text(
                'Your rating',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              RatingStars(
                rating: _ratingValue,
                iconSize: 28,
                showValue: true,
                onChanged: (rating) => setState(() => _ratingValue = rating),
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
