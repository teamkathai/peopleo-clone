/// Canonical endpoint paths used by the live backend.
/// These are reproduced verbatim from the original app and MUST NOT be changed.
class Endpoints {
  Endpoints._();

  // Auth
  static const login = '/login';
  static const mobLogin = '/mob-login';
  static const register = '/register';
  static const setPassword = '/set-password';
  static const validateOtp = '/validate-otp';
  static const forgotPass = '/forgot-pass';
  static const forgetPasswordEmp = '/forget-password-emp';
  static const changePassword = '/change-password';
  static const getKeys = '/get-keys';

  // Attendance & location
  static const employeePunch = '/employee-punch';
  static const employeePunchRecords = '/employee-punch-records';
  static const punchfailRecord = '/punchfail_record';
  static const attendanceReport = '/attendance-report';
  static const addLocation = '/add-location';
  static const locationList = '/location-list';
  static const assignLocations = '/assign-locations';
  static const showAvailability = '/show_availability';

  // Leave
  static const applyLeave = '/apply-leave';
  static const leaveApplicationList = '/leave-application-list';
  static const myLeaveList = '/myleave-list';
  static const leaveBalance = '/leave-balance';
  static const leaveStatus = '/leave-status';
  static const leaveTypeList = '/leavetype-list';
  static const requestedLeave = '/requested-leave';
  static const empLeaveAction = '/emp-leave-action';
  static const empLeaveCancelRequest = '/emp-leave-cancel-request';
  static const leavePortal = '/leave-portal';

  // Profile & org
  static const employeeDetailsByToken = '/employee-details-by-token';
  static const employeePersonalDetails = '/employee-personal-details';
  static const employeePersonalDetailsUpdate = '/employee-personal-details-update';
  static const employeePhotoUpdate = '/employee-photo-update';
  static const editPersonal = '/edit-personal';
  static const profileReplace = '/profile-replace';
  static const viewProfile = '/view-profile';
  static const listDesignation = '/list-designation';
  static const reportingAuthList = '/reporting-auth-list';
  static const showHierarchy = '/show_hierarchy';
  static const clientList = '/client-list';
  static const districtList = '/district-list';
  static const addressTypeList = '/address-type-list';

  // Expenses / resignation / misc
  static const addExpenses = '/add-expenses';
  static const applyResignation = '/apply-Resignation';
  static const resignation = '/resignation';
  static const noticeBoard = '/notice-board';
  static const notification = '/notification';
  static const createSupport = '/create-support';
  static const listSupport = '/list-support';
  static const contact = '/contact';
  static const blockList = '/block-list';
}
