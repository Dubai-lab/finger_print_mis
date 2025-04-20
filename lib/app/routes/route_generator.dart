import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_page.dart';
import '../../screens/admin/admin_dashboard.dart';
import '../../screens/student/student_dashboard.dart';
import '../../screens/instructor/instructor_dashboard.dart';
import '../../screens/invigilator/invigilator_dashboard.dart';
import '../../screens/admin/create_course_page.dart';
import '../../screens/admin/faculty_management_screen.dart';
import '../../screens/admin/department_management_screen.dart';
import '../../screens/admin/course_management_screen.dart';
import '../../screens/admin/session_manager_screen.dart';
import '../../screens/admin/manage_course_offerings_page.dart';
import '../../screens/student/view_available_course.dart';
import '../../screens/admin/manage_student_page.dart';

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
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        ),
      );
  }
}
