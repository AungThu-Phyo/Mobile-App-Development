import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

class SwapSpaceApp extends StatefulWidget {
  final AuthProvider authProvider;
  const SwapSpaceApp({super.key, required this.authProvider});

  @override
  State<SwapSpaceApp> createState() => _SwapSpaceAppState();
}

class _SwapSpaceAppState extends State<SwapSpaceApp> {
  late final _router = AppRouter.createRouter(widget.authProvider);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    AppColors.setDarkMode(themeProvider.isDarkMode);

    return MaterialApp.router(
      title: 'SwapSpace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return _ResponsiveAppFrame(child: child);
      },
    );
  }
}

class _ResponsiveAppFrame extends StatelessWidget {
  final Widget child;
  const _ResponsiveAppFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final useFrame = width >= 700;
        final horizontalPadding = width >= 1200 ? 28.0 : 16.0;
        final frameWidth = width >= 1280
            ? 1100.0
            : width >= 900
            ? 820.0
            : width - (horizontalPadding * 2);

        final content = useFrame
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: frameWidth),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color:
                            (isDarkMode ? AppColors.darkSurface : Colors.white)
                                .withValues(alpha: isDarkMode ? 0.94 : 0.92),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDarkMode
                              ? AppColors.darkGrey200
                              : const Color(0xFFE2E8DD),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? const Color(0x33000000)
                                : const Color(0x17000000),
                            blurRadius: 32,
                            offset: Offset(0, 20),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: child,
                      ),
                    ),
                  ),
                ),
              )
            : child;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? const [
                      Color(0xFF091317),
                      Color(0xFF102127),
                      Color(0xFF1B1710),
                    ]
                  : const [
                      Color(0xFFE8F6FF),
                      Color(0xFFF8F7F2),
                      Color(0xFFFFF4E8),
                    ],
            ),
          ),
          child: content,
        );
      },
    );
  }
}
