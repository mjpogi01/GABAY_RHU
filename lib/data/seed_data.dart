import '../models/module_model.dart';
import '../models/question_model.dart';
import '../repositories/module_repository.dart';
import '../repositories/assessment_repository.dart';

/// Seeds initial modules and questions
/// Expand to 50 modules and full question sets for production
class SeedData {
  static bool _seeded = false;

  static Future<void> ensureSeeded() async {
    if (_seeded) return;

    final modules = _getSampleModules();
    final preQuestions = _getPreTestQuestions();
    final postQuestions = _getPostTestQuestions();

    await ModuleRepository.seedModules(modules);
    await AssessmentRepository.seedQuestions([...preQuestions, ...postQuestions]);

    _seeded = true;
  }

  static List<ModuleModel> getSampleModules() => _getSampleModules();

  static List<ModuleModel> _getSampleModules() {
    return [
      ModuleModel(
        id: 'mod_newborn_1',
        title: 'Newborn Care Basics',
        domain: 'newborn_care',
        order: 1,
        cards: [
          const ModuleCard(
            id: 'c1',
            content: 'Keep your newborn warm and dry. Dress them in one more layer than you would wear.',
            order: 1,
          ),
          const ModuleCard(
            id: 'c2',
            content: 'Support your baby\'s head and neck when holding them. Newborns cannot hold their head up yet.',
            order: 2,
          ),
        ],
      ),
      ModuleModel(
        id: 'mod_nutrition_1',
        title: 'Breastfeeding Basics',
        domain: 'nutrition',
        order: 2,
        cards: [
          const ModuleCard(
            id: 'c3',
            content: 'Breast milk is the best food for your baby in the first 6 months. It has all the nutrients they need.',
            order: 1,
          ),
          const ModuleCard(
            id: 'c4',
            content: 'Feed your baby on demand—whenever they show signs of hunger. This helps build your milk supply.',
            order: 2,
          ),
        ],
      ),
      ModuleModel(
        id: 'mod_safety_1',
        title: 'Safe Sleep',
        domain: 'safety',
        order: 3,
        cards: [
          const ModuleCard(
            id: 'c5',
            content: 'Always put your baby to sleep on their back. This reduces the risk of sudden infant death.',
            order: 1,
          ),
          const ModuleCard(
            id: 'c6',
            content: 'Use a firm, flat sleep surface. Remove pillows, blankets, and toys from the crib.',
            order: 2,
          ),
        ],
      ),
      ModuleModel(
        id: 'mod_caregiving_1',
        title: 'Responsive Caregiving',
        domain: 'responsive_caregiving',
        order: 4,
        cards: [
          const ModuleCard(
            id: 'c7',
            content: 'Respond to your baby\'s cries. Crying is how they communicate their needs.',
            order: 1,
          ),
          const ModuleCard(
            id: 'c8',
            content: 'Talk and sing to your baby. Your voice helps them feel safe and supports language development.',
            order: 2,
          ),
        ],
      ),
      ModuleModel(
        id: 'mod_development_1',
        title: 'Early Development',
        domain: 'development',
        order: 5,
        cards: [
          const ModuleCard(
            id: 'c9',
            content: 'Tummy time helps strengthen your baby\'s neck and shoulders. Start with a few minutes each day.',
            order: 1,
          ),
          const ModuleCard(
            id: 'c10',
            content: 'Play and interact with your baby every day. Simple games like peek-a-boo support learning.',
            order: 2,
          ),
        ],
      ),
      ModuleModel(
        id: 'mod_wellbeing_1',
        title: 'Caregiver Well-being',
        domain: 'caregiver_wellbeing',
        order: 6,
        cards: [
          const ModuleCard(
            id: 'c11',
            content: 'Taking care of yourself helps you take better care of your baby. Rest when your baby sleeps.',
            order: 1,
          ),
          const ModuleCard(
            id: 'c12',
            content: 'Ask for help when you need it. Family, friends, and health workers can support you.',
            order: 2,
          ),
        ],
      ),
    ];
  }

  static List<QuestionModel> getPreTestQuestions() => _getPreTestQuestions();
  static List<QuestionModel> getPostTestQuestions() => _getPostTestQuestions();

  static List<QuestionModel> _getPreTestQuestions() {
    return [
      const QuestionModel(
        id: 'pre_1',
        pairedId: 'post_1',
        domain: 'newborn_care',
        text: 'When holding a newborn, what is important to support?',
        options: [
          'Feet only',
          'Head and neck',
          'Back only',
          'Legs only',
        ],
        correctIndex: 1,
        explanation: 'Newborns cannot hold their head up. Always support their head and neck.',
      ),
      const QuestionModel(
        id: 'pre_2',
        pairedId: 'post_2',
        domain: 'nutrition',
        text: 'What is the best food for a baby in the first 6 months?',
        options: [
          'Water',
          'Cow\'s milk',
          'Breast milk',
          'Juice',
        ],
        correctIndex: 2,
        explanation: 'Breast milk has all the nutrients a baby needs in the first 6 months.',
      ),
      const QuestionModel(
        id: 'pre_3',
        pairedId: 'post_3',
        domain: 'safety',
        text: 'What is the safest position for a baby to sleep?',
        options: [
          'On stomach',
          'On side',
          'On back',
          'Propped up',
        ],
        correctIndex: 2,
        explanation: 'Sleeping on the back reduces the risk of sudden infant death.',
      ),
      const QuestionModel(
        id: 'pre_4',
        pairedId: 'post_4',
        domain: 'responsive_caregiving',
        text: 'When your baby cries, what should you do?',
        options: [
          'Ignore them',
          'Respond to them',
          'Wait a long time',
          'Leave the room',
        ],
        correctIndex: 1,
        explanation: 'Crying is how babies communicate. Responding helps them feel safe.',
      ),
      const QuestionModel(
        id: 'pre_5',
        pairedId: 'post_5',
        domain: 'caregiver_wellbeing',
        text: 'Why is it important for caregivers to rest?',
        options: [
          'It is not important',
          'To take better care of the baby',
          'Only at night',
          'Never',
        ],
        correctIndex: 1,
        explanation: 'Rest helps caregivers stay healthy and take better care of their baby.',
      ),
    ];
  }

  static List<QuestionModel> _getPostTestQuestions() {
    return [
      const QuestionModel(
        id: 'post_1',
        pairedId: 'pre_1',
        domain: 'newborn_care',
        text: 'Which part of a newborn should you hold and support when carrying them?',
        options: [
          'Only the body',
          'The head and neck',
          'Only the legs',
          'The arms',
        ],
        correctIndex: 1,
        explanation: 'Supporting the head and neck is essential for newborn safety.',
      ),
      const QuestionModel(
        id: 'post_2',
        pairedId: 'pre_2',
        domain: 'nutrition',
        text: 'Which food provides the best nutrition for infants 0-6 months old?',
        options: [
          'Formula only',
          'Breast milk',
          'Rice water',
          'Honey',
        ],
        correctIndex: 1,
        explanation: 'Breast milk is the ideal food for infants in the first 6 months.',
      ),
      const QuestionModel(
        id: 'post_3',
        pairedId: 'pre_3',
        domain: 'safety',
        text: 'To reduce sleep-related risks, babies should be placed to sleep:',
        options: [
          'Face down',
          'On their side',
          'On their back',
          'In a swing',
        ],
        correctIndex: 2,
        explanation: 'Back sleeping is the safest position for infants.',
      ),
      const QuestionModel(
        id: 'post_4',
        pairedId: 'pre_4',
        domain: 'responsive_caregiving',
        text: 'What is the best response when an infant cries?',
        options: [
          'Let them cry it out',
          'Check and respond to their needs',
          'Cover their ears',
          'Move to another room',
        ],
        correctIndex: 1,
        explanation: 'Responding to cries builds trust and meets the baby\'s needs.',
      ),
      const QuestionModel(
        id: 'post_5',
        pairedId: 'pre_5',
        domain: 'caregiver_wellbeing',
        text: 'Caregivers need rest because it helps them:',
        options: [
          'Sleep less',
          'Care for the baby better',
          'Ignore the baby',
          'Work more',
        ],
        correctIndex: 1,
        explanation: 'Rest supports caregiver health and quality of care.',
      ),
    ];
  }
}
