import '../config/app_config.dart';

const String kBaseUrl = AppConfig.baseUrl;

const String kRegisterUrl = '/api/users/register/';
const String kLoginUrl = '/api/users/login/';
const String kProfileUrl = '/api/users/profile/';
const String kLogoutUrl = '/api/users/logout/';

const String kScanUrl = '/api/scan/';
const String kScanHistoryUrl = '/api/scan/history/';

// Role-based panels
const String kAdminUsersUrl = '/api/users/admin/users/';
const String kExpertUsersUrl = '/api/users/expert/users/';

const String kGetAllQuestionsUrl = '/api/questions/get-all-questions/';
const String kCreateQuestionUrl = '/api/question/create-question/';
const String kCreateAnswerUrl = '/api/answer/create-answer/';
const String kAnswerBaseUrl = '/api/answer/';

// Subscriptions
const String kGetPlansUrl = '/api/get-plans/';
const String kCreateSubscriptionPaymentUrl =
    '/api/subscriptions/create-subscription-payment/';

// Catalog (premium)
const String kCatalogPlantsUrl = '/api/catalog/crops/';
const String kCatalogSolutionsUrl = '/api/catalog/solutions/';
