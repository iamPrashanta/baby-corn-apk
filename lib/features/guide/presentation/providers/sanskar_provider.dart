import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../domain/models/sanskar_model.dart';
import '../../../auth/presentation/providers/baby_provider.dart';

final sanskarsProvider = StateNotifierProvider<SanskarNotifier, List<SanskarModel>>((ref) {
  final activeBaby = ref.watch(activeBabyProvider);
  return SanskarNotifier(activeBaby?.id);
});

class SanskarNotifier extends StateNotifier<List<SanskarModel>> {
  final String? _activeBabyId;

  SanskarNotifier(this._activeBabyId) : super([]) {
    _loadSanskars();
  }

  String get _prefix => _activeBabyId != null ? '${_activeBabyId}_' : '';

  void _loadSanskars() {
    final box = HiveManager.getSanskarsBox();
    
    // Get all sanskars that match the active baby's prefix
    var babySanskars = box.values.where((s) => s.id.startsWith(_prefix)).toList();
    
    if (babySanskars.isEmpty) {
      _initializeDefaultSanskars();
      babySanskars = box.values.where((s) => s.id.startsWith(_prefix)).toList();
    }
    state = babySanskars;
  }

  void _initializeDefaultSanskars() {
    final box = HiveManager.getSanskarsBox();
    final defaultSanskars = _getDefault18Sanskars();
    for (var sanskar in defaultSanskars) {
      final namespacedId = '$_prefix${sanskar.id}';
      final namespacedSanskar = sanskar.copyWith(id: namespacedId);
      box.put(namespacedId, namespacedSanskar);
    }
  }

  void markCompleted(String id, bool completed) {
    final box = HiveManager.getSanskarsBox();
    final item = box.get(id);
    if (item != null) {
      final updated = item.copyWith(isCompleted: completed);
      box.put(id, updated);
      _refreshState();
    }
  }

  void updateCustomDate(String id, DateTime? newDate) {
    final box = HiveManager.getSanskarsBox();
    final item = box.get(id);
    if (item != null) {
      final updated = item.copyWith(customDate: newDate);
      box.put(id, updated);
      _refreshState();
    }
  }

  void updateNotes(String id, String notes) {
    final box = HiveManager.getSanskarsBox();
    final item = box.get(id);
    if (item != null) {
      final updated = item.copyWith(notes: notes);
      box.put(id, updated);
      _refreshState();
    }
  }

  void toggleReminder(String id, bool enabled) {
    final box = HiveManager.getSanskarsBox();
    final item = box.get(id);
    if (item != null) {
      final updated = item.copyWith(reminderEnabled: enabled);
      box.put(id, updated);
      _refreshState();
    }
  }
  
  void _refreshState() {
    final box = HiveManager.getSanskarsBox();
    state = box.values.where((s) => s.id.startsWith(_prefix)).toList();
  }

  List<SanskarModel> _getDefault18Sanskars() {
    return [
      SanskarModel(
        id: 's_01',
        name: 'Garbhadhana',
        sanskritName: 'गर्भाधान',
        description: 'Conception ritual praying for a healthy child.',
        category: 'Prenatal',
        emojiIcon: '🌸',
        defaultRule: SanskarRule(offset: 280, unit: SanskarOffsetUnit.beforeBirth, traditionalTimingText: 'Before conception'),
      ),
      SanskarModel(
        id: 's_02',
        name: 'Pumsavana',
        sanskritName: 'पुंसवन',
        description: 'Ritual for the physical and mental growth of the baby.',
        category: 'Prenatal',
        emojiIcon: '🌱',
        defaultRule: SanskarRule(offset: 200, unit: SanskarOffsetUnit.beforeBirth, traditionalTimingText: '2–3 months of pregnancy'),
      ),
      SanskarModel(
        id: 's_03',
        name: 'Simantonnayana',
        sanskritName: 'सीमान्तोन्नयन',
        description: 'Baby shower ritual for the mother\'s joy and positivity.',
        category: 'Prenatal',
        emojiIcon: '🪔',
        defaultRule: SanskarRule(offset: 60, unit: SanskarOffsetUnit.beforeBirth, traditionalTimingText: '7–8 months of pregnancy'),
      ),
      SanskarModel(
        id: 's_04',
        name: 'Jatakarma',
        sanskritName: 'जातकर्म',
        description: 'Welcoming the newborn into the world with honey/ghee.',
        category: 'Birth',
        emojiIcon: '👶',
        defaultRule: SanskarRule(offset: 0, unit: SanskarOffsetUnit.days, traditionalTimingText: 'At birth'),
      ),
      SanskarModel(
        id: 's_05',
        name: 'Namakarana',
        sanskritName: 'नामकरण',
        description: 'The naming ceremony of the child.',
        category: 'Infancy',
        emojiIcon: '✍️',
        defaultRule: SanskarRule(offset: 21, unit: SanskarOffsetUnit.days, traditionalTimingText: '11th or 21st day'),
      ),
      SanskarModel(
        id: 's_06',
        name: 'Nishkramana',
        sanskritName: 'निष्क्रमण',
        description: 'The baby\'s first outing to see the sun/temple.',
        category: 'Infancy',
        emojiIcon: '☀️',
        defaultRule: SanskarRule(offset: 4, unit: SanskarOffsetUnit.months, traditionalTimingText: '4th month'),
      ),
      SanskarModel(
        id: 's_07',
        name: 'Annaprashana',
        sanskritName: 'अन्नप्राशन',
        description: 'The baby\'s first taste of solid food.',
        category: 'Infancy',
        emojiIcon: '🥣',
        defaultRule: SanskarRule(offset: 6, unit: SanskarOffsetUnit.months, traditionalTimingText: '6th month'),
      ),
      SanskarModel(
        id: 's_08',
        name: 'Karnavedha',
        sanskritName: 'कर्णवेध',
        description: 'Ear piercing ritual for health and intellect.',
        category: 'Childhood',
        emojiIcon: '👂',
        defaultRule: SanskarRule(offset: 12, unit: SanskarOffsetUnit.months, traditionalTimingText: '6–12 months'),
      ),
      SanskarModel(
        id: 's_09',
        name: 'Mundan / Chudakarana',
        sanskritName: 'चूड़ाकर्म',
        description: 'First haircut, symbolizing purity and new beginnings.',
        category: 'Childhood',
        emojiIcon: '✂️',
        defaultRule: SanskarRule(offset: 1, unit: SanskarOffsetUnit.years, traditionalTimingText: '1st, 3rd, or 5th year'),
      ),
      SanskarModel(
        id: 's_10',
        name: 'Vidyarambha',
        sanskritName: 'विद्यारम्भ',
        description: 'Initiation into reading and writing.',
        category: 'Childhood',
        emojiIcon: '📖',
        defaultRule: SanskarRule(offset: 5, unit: SanskarOffsetUnit.years, traditionalTimingText: 'Around 5 years'),
      ),
      SanskarModel(
        id: 's_11',
        name: 'Upanayana',
        sanskritName: 'उपनयन',
        description: 'The sacred thread ceremony; entering the student phase.',
        category: 'Adolescence',
        emojiIcon: '🧶',
        defaultRule: SanskarRule(offset: 8, unit: SanskarOffsetUnit.years, traditionalTimingText: '8–12 years'),
      ),
      SanskarModel(
        id: 's_12',
        name: 'Vedarambha',
        sanskritName: 'वेदारम्भ',
        description: 'Commencement of deep study and education.',
        category: 'Adolescence',
        emojiIcon: '📚',
        defaultRule: SanskarRule(offset: 9, unit: SanskarOffsetUnit.years, traditionalTimingText: 'Education initiation'),
      ),
      SanskarModel(
        id: 's_13',
        name: 'Keshanta',
        sanskritName: 'केशान्त',
        description: 'First shave of facial hair, marking maturity.',
        category: 'Teenage',
        emojiIcon: '🪒',
        defaultRule: SanskarRule(offset: 16, unit: SanskarOffsetUnit.years, traditionalTimingText: 'Teenage years'),
      ),
      SanskarModel(
        id: 's_14',
        name: 'Samavartana',
        sanskritName: 'समावर्तन',
        description: 'Graduation from studies, returning home.',
        category: 'Young Adult',
        emojiIcon: '🎓',
        defaultRule: SanskarRule(offset: 21, unit: SanskarOffsetUnit.years, traditionalTimingText: 'Graduation age'),
      ),
      SanskarModel(
        id: 's_15',
        name: 'Vivaha',
        sanskritName: 'विवाह',
        description: 'Marriage; entering the householder phase of life.',
        category: 'Adulthood',
        emojiIcon: '💍',
        defaultRule: SanskarRule(offset: 25, unit: SanskarOffsetUnit.years, traditionalTimingText: 'Marriage'),
      ),
      SanskarModel(
        id: 's_16',
        name: 'Vanaprastha',
        sanskritName: 'वानप्रस्थ',
        description: 'Stepping back from worldly duties, embracing spirituality.',
        category: 'Elderly',
        emojiIcon: '🍂',
        defaultRule: SanskarRule(offset: 50, unit: SanskarOffsetUnit.years, traditionalTimingText: 'Around 50 years'),
      ),
      SanskarModel(
        id: 's_17',
        name: 'Sannyasa',
        sanskritName: 'संन्यास',
        description: 'Complete renunciation for spiritual liberation.',
        category: 'Elderly',
        emojiIcon: '🕉️',
        defaultRule: SanskarRule(offset: 75, unit: SanskarOffsetUnit.years, traditionalTimingText: 'Around 75 years'),
      ),
      SanskarModel(
        id: 's_18',
        name: 'Antyeshti',
        sanskritName: 'अन्त्येष्टि',
        description: 'The final rites; return to the five elements.',
        category: 'End of Life',
        emojiIcon: '🕊️',
        defaultRule: SanskarRule(offset: 100, unit: SanskarOffsetUnit.years, traditionalTimingText: 'End-of-life'),
      ),
    ];
  }
}
