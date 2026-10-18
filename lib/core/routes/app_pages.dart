import 'package:get/get.dart';
import 'package:namaz_alert/core/routes/app_routes.dart';
import 'package:namaz_alert/features/auth/controller/auth_controller.dart';
import 'package:namaz_alert/features/auth/view/login_screen.dart';
import 'package:namaz_alert/features/auth/view/register_screen.dart';
import 'package:namaz_alert/features/auth/view/splash_screen.dart';
import 'package:namaz_alert/features/group/controller/group_controller.dart';
import 'package:namaz_alert/features/group/view/create_group_screen.dart';
import 'package:namaz_alert/features/group/view/group_detail_screen.dart';
import 'package:namaz_alert/features/group/view/groups_screen.dart';
import 'package:namaz_alert/features/home/view/home_screen.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
      }),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: AppRoutes.groups,
      page: () => const GroupsScreen(),
      binding: BindingsBuilder(() {
        Get.put(GroupController());
      }),
    ),
    GetPage(
      name: AppRoutes.createGroup,
      page: () => const CreateGroupScreen(),
    ),
    GetPage(
      name: AppRoutes.groupDetail,
      page: () => const GroupDetailScreen(),
    ),
  ];
}
