import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/user_model.dart';
import 'models/club_model.dart';
import 'models/limits_model.dart';
import 'screens/onboarding_walkthrough.dart';
import 'screens/login_signup_page.dart';
import 'screens/user_profile.dart';
import 'screens/club_create_or_join.dart';
import 'services/authentication.dart';
import 'screens/home_page.dart';
import 'services/firestore_helper.dart';
import 'screens/widgets/enforce_update.dart';
import 'services/presets.dart';

enum AuthStatus {
  notDetermined,
  notLoggedIn,
  loggedIn,
}

enum SetupStatus {
  walkthroughCompleted,
  walkthroughNotYetStarted,
  profileIncomplete,
  clubNotChosen,
  minAppVersionNotSatisfied,
  notDetermined
}

final Auth auth = Auth();
final fsHelper = FSHelper.instance;
final userProvider = FutureProvider.autoDispose<UserModel>((ref) async {
  UserModel userData;
  try {
    userData = await fsHelper.getUserData(auth.getCurrentUser()) ?? UserModel();
  } catch (e) {
    userData = UserModel();
  }
  return userData;
});

class RootPage extends ConsumerWidget {
  final bool newClubRouteCompleted;

  const RootPage({super.key, this.newClubRouteCompleted = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AuthStatus authStatus = AuthStatus.notDetermined;
    SetupStatus setupStatus = SetupStatus.notDetermined;

    String deviceToken = "", deviceAuthStatus = "";
    bool accessedBefore = false;

    String? userId;
    ClubModel? clubData;
    List<UserModel>? guardedPlayers;
    bool userIsAdmin = false;
    String minAppVersion = "";
    LimitModel limits = LimitModel.defaultLimits;

    Widget buildWaitingScreen() {
      return Scaffold(
        body: Container(),
      );
    }

    logAccess(ClubModel? club, userId) async {
      // code removed
    }

    Future<ClubModel> navToChooseClub(
        BuildContext context, UserModel user) async {
      final club = await Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => ClubCreateOrJoinPage(
                  title: AppLocalizations.of(context).joinOrCreateAClub,
                  auth: auth,
                  user: user,
                  walkThrough: true,
                )),
      );
      return club;
    }

    navToEnforceUpgrade(BuildContext context, minAppVersion, UserModel user) {
      Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => EnforceUpdate(
                  auth: auth,
                  user: user,
                  version: minAppVersion,
                )),
      );
    }

    Future<void> saveDeviceToken(userId) async {
      await fsHelper.saveDeviceTokenandAuthStatus(
          userId, deviceToken, deviceAuthStatus);
    }

    Future initSetupStatusAndUserAndClub(
        BuildContext context, UserModel userData) async {
      final prefs = await SharedPreferences.getInstance();
      deviceToken = prefs.getString('deviceToken') ?? "";
      deviceAuthStatus = prefs.getString('authorizationStatus') ?? "";
      accessedBefore = prefs.getBool('accessed_before') ?? false;
      debugPrint("accessedBefore: ${accessedBefore.toString()}");
      if (authStatus == AuthStatus.notLoggedIn) {
        if (!accessedBefore) setupStatus = SetupStatus.walkthroughNotYetStarted;
        return;
      }
      if (accessedBefore) {
        setupStatus = SetupStatus.walkthroughCompleted;
        debugPrint('UserId: ${userData.id}');
        if (userData.firstName == null ||
            userData.lastName == null ||
            userData.phoneNumber == null ||
            userData.firstName == '' ||
            userData.lastName == '' ||
            userData.phoneNumber == '' /*|| userData?.image == null */) {
          setupStatus = SetupStatus.profileIncomplete;
        }
        final clubID = prefs.getString('clubID');
        clubData = clubID != '' ? await fsHelper.getClubData(clubID) : null;
        // debugPrint("clubData: ${clubData?.toJson().toString()}");
        final bool approvedClub = clubData?.approvedClub ?? false;
        final bool userIsPartofClub =
            userData.clubIDs?.contains(clubID) ?? false;
        userIsAdmin = newClubRouteCompleted
            ? true
            : ClubFeatures.isCurrentClubAdmin(userData, clubData);
        debugPrint("userIsAdmin: $userIsAdmin");
        debugPrint(
            "clubData: $clubData || approvedClub: $approvedClub || userIsPartofClub: $userIsPartofClub && setupStatus: $setupStatus");
        if ((clubData == null || !approvedClub || !userIsPartofClub) &&
            setupStatus != SetupStatus.profileIncomplete &&
            !newClubRouteCompleted) {
          //TODO: Refactor to include in switch statement below
          setupStatus = SetupStatus.clubNotChosen;
          FlutterNativeSplash.remove();
          if (!context.mounted) return;
          clubData = await navToChooseClub(context, userData);
        }
        await logAccess(clubData, userData.id);
        await saveDeviceToken(userId);
      } else {
        setupStatus = SetupStatus.walkthroughNotYetStarted;
      }
    }

    void loginCallback() {
      userId = auth.getCurrentUser();
      authStatus = AuthStatus.loggedIn;
      setupStatus = SetupStatus.profileIncomplete;
      final refResponse = ref.refresh(userProvider);
    }

    void logoutCallback() async {
      authStatus = AuthStatus.notLoggedIn;
      await auth.signOut();
      final refResponse = ref.refresh(userProvider);
      userId = "";
    }

    userId = auth.getCurrentUser();
    authStatus = userId == null ? AuthStatus.notLoggedIn : AuthStatus.loggedIn;
    AsyncValue<UserModel> userData = ref.watch(userProvider);
    return userData.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) {
        debugPrint("Error: $err");
        return Container();
      },
      data: (userData) {
        return FutureBuilder<void>(
          future: initSetupStatusAndUserAndClub(context, userData),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              debugPrint("setupStatus: $setupStatus");
              debugPrint("authStatus: $authStatus");
              debugPrint("User: ${userData.id}");
              debugPrint("Club: ${clubData?.id}");
              debugPrint("userId: $userId");
              // debugPrint("userData: ${userData.toJson().toString()}");
              FlutterNativeSplash.remove();
              switch (setupStatus) {
                case SetupStatus
                      .minAppVersionNotSatisfied: // TODO: test after functions are connected
                  navToEnforceUpgrade(context, minAppVersion, userData);
                  break;

                case SetupStatus.walkthroughNotYetStarted:
                  return WalkthroughScreen(
                    auth: auth,
                  );

                case SetupStatus.profileIncomplete:
                  return ProfilePage(
                    title: AppLocalizations.of(context).setUpYourProfile,
                    userId: userId,
                    auth: auth,
                    logoutCallback: logoutCallback,
                    walkThrough: true,
                  );

                default:
                  switch (authStatus) {
                    case AuthStatus.notDetermined:
                      return buildWaitingScreen();
                    case AuthStatus.notLoggedIn:
                      return LoginSignupPage(
                        auth: auth,
                        loginCallback: loginCallback,
                        walkthrough: false,
                      );
                    case AuthStatus.loggedIn:
                      if (userId!.isNotEmpty) {
                        debugPrint("case AuthStatus.loggedIn reached");
                        saveUserId(userId!);
                        return HomePage(
                            userId: userId!,
                            user: userData,
                            club: clubData!,
                            auth: auth,
                            logoutCallback: logoutCallback,
                            guardedPlayers: guardedPlayers,
                            context: context,
                            adminMode: userIsAdmin,
                            limits: limits);
                      } else {
                        return Container(
                          width: 0,
                        );
                      }
                    default:
                      return buildWaitingScreen();
                  }
              }
            } else {
              return Container(
                width: 0,
              );
            }
            return Container();
          },
        );
      },
    );
  }
}

class RootPageRefactored extends StatelessWidget {
  final bool newClubRouteCompleted;

  RootPageRefactored({super.key, this.newClubRouteCompleted = false});

  String? userId = auth.getCurrentUser();
  AuthStatus authStatus;
  late SetupStatus setupStatus = SetupStatus.notDetermined;
  late bool accessedBefore;

  ClubModel? clubData;
  List<UserModel>? guardedPlayers;
  bool userIsAdmin = false;
  String minAppVersion = "";
  LimitModel limits = LimitModel.defaultLimits;

  @override
  Widget build(BuildContext context) {
    /*
    * Should NOT init the default value on the build method of Widget
    * It's will make the method become to more complex
    * and leading the issue performance when the widget is rebuilt
    * */

    // userId = auth.getCurrentUser();
    authStatus = userId == null ? AuthStatus.notLoggedIn : AuthStatus.loggedIn;

    AsyncValue<UserModel> userData = ref.watch(userProvider);
    return userData.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => errorPage,
      data: (userData) {
        return FutureBuilder(
          future: initSetupStatusAndUserAndClub(context, userData),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return emptyBox;
            }
            FlutterNativeSplash.remove();
            return _getNextScreenByCheckingSetupAndAuthStatus(
              context,
              userData,
            );
          },
        );
      },
    );
  }

  /// this method is using for saving the userID for future use in the app
  saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  /*
  * Should NOT create a widget by a method, it's not good for performance
  * Should create it by a separate Stateful or Stateless widget.
  * */
  Widget buildWaitingScreen() {
    return const Scaffold(
      body: Text('Waiting screen'),
    );
  }

  /*
  * This is an event method, should not return a value
  * */
  Future<ClubModel> navToChooseClub(
    BuildContext context,
    UserModel user,
  ) async {
    final club = await Navigator.push(
      context,
      MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => ClubCreateOrJoinPage(
                title: AppLocalizations.of(context).joinOrCreateAClub,
                auth: auth,
                user: user,
                walkThrough: true,
              )),
    );
    return club;
  }

  navToEnforceUpgrade(
    BuildContext context,
    minAppVersion,
    UserModel user,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => EnforceUpdate(
                auth: auth,
                user: user,
                version: minAppVersion,
              )),
    );
  }

  /// if the method return the Future<void>
  /// just use Future instead, it's enough
  Future saveDeviceToken(
    String userId,
    String deviceToken,
    String deviceAuthStatus,
  ) async {
    await fsHelper.saveDeviceTokenandAuthStatus(
      userId,
      deviceToken,
      deviceAuthStatus,
    );
  }

  Future initSetupStatusAndUserAndClub(
    BuildContext context,
    UserModel userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    bool accessedBefore = prefs.getBool('accessed_before') ?? false;
    SetupStatus setupStatus;

    if (authStatus != AuthStatus.notLoggedIn && accessedBefore) {
      setupStatus = getSetUpStatusByUserData(userData);

      final clubID = prefs.getString('clubID');
      clubData = clubID != '' ? await fsHelper.getClubData(clubID) : null;
      final bool approvedClub = clubData?.approvedClub ?? false;
      final bool userIsPartOfClub = userData.clubIDs?.contains(clubID) ?? false;
      userIsAdmin = newClubRouteCompleted
          ? true
          : ClubFeatures.isCurrentClubAdmin(userData, clubData);

      if ((clubData == null || !approvedClub || !userIsPartOfClub) &&
          setupStatus != SetupStatus.profileIncomplete &&
          !newClubRouteCompleted) {
        setupStatus = SetupStatus.clubNotChosen;
        FlutterNativeSplash.remove();

        //TODO: MAYBE THE PROBLEM IS HERE
        if (!context.mounted) return;

        await logAccess(clubData, userData.id);
        await saveDeviceToken(userId);
        clubData = await navToChooseClub(context, userData);
      }

      /// Should execute all the event before navigate to the next screen
      await logAccess(clubData, userData.id);
      await saveDeviceToken(userId);
    } else {
      setupStatus = SetupStatus.walkthroughNotYetStarted;
    }
  }

  loginCallback(WidgetRef ref) {
    String userId = auth.getCurrentUser();
    authStatus = AuthStatus.loggedIn;
    setupStatus = SetupStatus.profileIncomplete;
    ref.refresh(userProvider);
  }

  logoutCallback(WidgetRef ref) async {
    authStatus = AuthStatus.notLoggedIn;
    await auth.signOut();
    final refResponse = ref.refresh(userProvider);
    debugPrint("refResponse: $refResponse");
    userId = "";
  }

  /// Create a method to check the SetupStatus
  /// If there is a field is NULL, return the status: SetupStatus.profileIncomplete
  /// The default of this method is SetupStatus.walkthroughCompleted
  SetupStatus getSetUpStatusByUserData(UserModel userData) {
    if (userData.firstName == null ||
        userData.lastName == null ||
        userData.phoneNumber == null ||
        userData.firstName == '' ||
        userData.lastName == '' ||
        userData.phoneNumber == '') {
      return SetupStatus.profileIncomplete;
    }
    return SetupStatus.walkthroughCompleted;
  }

  /// Create a method to get the next screen by [SetUp] and [Auth] status
  /// This method will return an empty widget if...
  Widget _getNextScreenByCheckingSetupAndAuthStatus(
    BuildContext context,
    UserModel userData,
  ) {
    switch (setupStatus) {
      case SetupStatus.minAppVersionNotSatisfied:
        // TODO: test after functions are connected
        navToEnforceUpgrade(context, minAppVersion, userData);
        break;

      case SetupStatus.walkthroughNotYetStarted:
        return WalkthroughScreen(
          auth: auth,
        );

      case SetupStatus.profileIncomplete:
        return ProfilePage(
          title: AppLocalizations.of(context).setUpYourProfile,
          userId: userId,
          auth: auth,
          logoutCallback: logoutCallback,
          walkThrough: true,
        );

      default:
        switch (authStatus) {
          case AuthStatus.notDetermined:
            return buildWaitingScreen();
          case AuthStatus.notLoggedIn:
            return LoginSignupPage(
              auth: auth,
              loginCallback: loginCallback,
              walkthrough: false,
            );
          case AuthStatus.loggedIn:
            if (userId!.isEmpty) return emptyBox;
            saveUserId(userId!);
            return HomePage(
                userId: userId!,
                user: userData,
                club: clubData!,
                auth: auth,
                logoutCallback: logoutCallback,
                guardedPlayers: guardedPlayers,
                context: context,
                adminMode: userIsAdmin,
                limits: limits);
          default:
            return emptyBox;
        }
    }
    //TODO: MAYBE TO PROBLEM IS HERE
    return emptyBox;
  }
}

const Widget emptyBox = SizedBox.shrink();

Widget errorPage = const Text('Error page');
