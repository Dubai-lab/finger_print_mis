import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_page.dart';
import '../../screens/admin/admin_dashboard.dart';
import '../../screens/student/student_dashboard.dart';
import '../../screens/instructor/instructor_dashboard.dart';
import '../../screens/instructor/instructor_profile.dart';
import '../../screens/instructor/attendance_page.dart';
import '../../screens/invigilator/invigilator_dashboard.dart';
import '../../screens/admin/create_course_page.dart';
import '../../screens/admin/faculty_management_screen.dart';
import '../../screens/admin/department_management_screen.dart';
import '../../screens/admin/course_management_screen.dart';
import '../../screens/admin/session_manager_screen.dart';
import '../../screens/admin/manage_course_offerings_page.dart';
import '../../screens/student/view_available_course.dart';
import '../../screens/admin/manage_student_page.dart';
import '../../screens/admin/delete_recently_accessed_courses.dart';
import '../../screens/instructor/manage_attendance.dart';
import '../../screens/instructor/created_attendance_page.dart';
import '../../screens/instructor/instructor_course_students.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => const LoginPage());
    case AppRoutes.adminDashboard:
      return MaterialPageRoute(builder: (_) => const AdminDashboard());
    case AppRoutes.studentDashboard:
      return MaterialPageRoute(builder: (_) => const StudentDashboard());
    case AppRoutes.instructorDashboard:
      return MaterialPageRoute(builder: (_) => const InstructorDashboard());
    case AppRoutes.attendancePage:
      final args = settings.arguments as Map<String, dynamic>?;
      final courseOfferingId = args?['courseOfferingId'] as String?;
      if (courseOfferingId == null) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Missing courseOfferingId argument')),
          ),
        );
      }
      return MaterialPageRoute(
        builder: (_) => AttendancePage(courseOfferingId: courseOfferingId),
      );
    case AppRoutes.manageAttendance:
      final args = settings.arguments as Map<String, dynamic>?;
      final courseOfferingId = args?['courseOfferingId'] as String?;
      if (courseOfferingId == null) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Missing courseOfferingId argument')),
          ),
        );
      }
      return MaterialPageRoute(
        builder: (_) => ManageAttendancePage(courseOfferingId: courseOfferingId),
      );
    case AppRoutes.invigilatorDashboard:
      return MaterialPageRoute(builder: (_) => const InvigilatorDashboard());
    case AppRoutes.createCourse:
      return MaterialPageRoute(builder: (_) => const CreateCoursePage());
    case AppRoutes.facultyManagement:
      return MaterialPageRoute(builder: (_) => const FacultyManagementScreen());
    case AppRoutes.departmentManagement:
      return MaterialPageRoute(builder: (_) => const DepartmentManagementScreen());
    case AppRoutes.courseManagement:
      return MaterialPageRoute(builder: (_) => const CourseManagementScreen());
    case AppRoutes.sessionManager:
      return MaterialPageRoute(builder: (_) => const SessionManagerScreen());
    case AppRoutes.manageCourseOfferings:
      return MaterialPageRoute(builder: (_) => const ManageCourseOfferingsPage());
    case AppRoutes.manageStudents:
      return MaterialPageRoute(builder: (_) => const ManageStudentPage());
    case AppRoutes.studentAvailableCourses:
      return MaterialPageRoute(builder: (_) => const ViewAvailableCourse());
    case AppRoutes.deleteRecentlyAccessedCourses:
      return MaterialPageRoute(builder: (_) => const DeleteRecentlyAccessedCourses());
    case AppRoutes.createdAttendancePage:
      return MaterialPageRoute(builder: (_) => const CreatedAttendancePage());
    case AppRoutes.instructorProfile:
      return MaterialPageRoute(builder: (_) => const InstructorProfile());
    case AppRoutes.instructorCourseStudents:
      final args = settings.arguments as Map<String, dynamic>?;
      final courseOfferingId = args?['courseOfferingId'] as String?;
      if (courseOfferingId == null) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Missing courseOfferingId argument')),
          ),
        );
      }
      return MaterialPageRoute(
        builder: (_) => InstructorCourseStudents(courseOfferingId: courseOfferingId),
      );
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('No route defined for \${settings.name}'),
          ),
        ),
      );
  }
}
