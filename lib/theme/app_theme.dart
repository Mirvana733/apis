import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppRadius {
  const AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 26;
  static const double xxl = 32;
  static const double full = 999;

  static BorderRadius circular(double value) => BorderRadius.circular(value);
}

class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppTheme {
  const AppTheme._();

  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: AppColors.cristal,
    onPrimary: AppColors.profundoFuerte,
    primaryContainer: AppColors.cristalSuave,
    onPrimaryContainer: AppColors.profundoFuerte,
    secondary: AppColors.estrella,
    onSecondary: AppColors.profundo,
    secondaryContainer: AppColors.estrellaSuave,
    onSecondaryContainer: AppColors.profundo,
    tertiary: AppColors.cristalMedio,
    onTertiary: AppColors.profundoFuerte,
    surface: AppColors.perla,
    onSurface: AppColors.profundo,
    onSurfaceVariant: AppColors.profundoSuave,
    surfaceContainerLowest: AppColors.white,
    surfaceContainerLow: AppColors.perlaSuave,
    surfaceContainer: AppColors.white,
    surfaceContainerHigh: Color(0xFFF0F8FC),
    surfaceContainerHighest: AppColors.cristalSuave,
    outline: AppColors.bordeClaro,
    outlineVariant: AppColors.bordeMuyClaro,
    error: AppColors.danger,
    onError: AppColors.white,
    errorContainer: Color(0xFFFCE9E7),
    onErrorContainer: Color(0xFF7A1F17),
    inverseSurface: AppColors.profundoFuerte,
    onInverseSurface: AppColors.perla,
    inversePrimary: AppColors.cristalClaro,
    shadow: Color(0x1A173B52),
    scrim: Color(0x66173B52),
  );

  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: AppColors.cristal,
    onPrimary: AppColors.nocheProfunda,
    primaryContainer: AppColors.superficieOscuraMax,
    onPrimaryContainer: AppColors.cristalClaro,
    secondary: AppColors.estrella,
    onSecondary: AppColors.profundoFuerte,
    secondaryContainer: Color(0xFF3A351C),
    onSecondaryContainer: Color(0xFFF8E6A3),
    tertiary: AppColors.cristalMedio,
    onTertiary: AppColors.nocheProfunda,
    surface: AppColors.noche,
    onSurface: AppColors.textoClaro,
    onSurfaceVariant: AppColors.textoClaroSuave,
    surfaceContainerLowest: AppColors.nocheProfunda,
    surfaceContainerLow: Color(0xFF122B3C),
    surfaceContainer: AppColors.superficieOscura,
    surfaceContainerHigh: AppColors.superficieOscuraAlta,
    surfaceContainerHighest: AppColors.superficieOscuraMax,
    outline: AppColors.bordeOscuro,
    outlineVariant: AppColors.bordeOscuroSuave,
    error: Color(0xFFFF8A80),
    onError: Color(0xFF3B0A06),
    errorContainer: Color(0xFF5C1F1A),
    onErrorContainer: Color(0xFFFFDAD5),
    inverseSurface: AppColors.textoClaro,
    onInverseSurface: AppColors.profundoFuerte,
    inversePrimary: AppColors.cristalProfundo,
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
  );

  static ThemeData get light => _build(_lightScheme, Brightness.light);

  static ThemeData get dark => _build(_darkScheme, Brightness.dark);

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final botonShape = RoundedRectangleBorder(
      borderRadius: AppRadius.circular(AppRadius.md),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      splashColor: scheme.primary.withValues(alpha: 0.08),
      highlightColor: scheme.primary.withValues(alpha: 0.04),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display,
        headlineMedium: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.bodyStrong,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.bodyStrong,
        labelMedium: AppTextStyles.caption,
        labelSmall: AppTextStyles.overline,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headline.copyWith(
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurface),
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        labelStyle: AppTextStyles.body.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: AppTextStyles.caption.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: AppTextStyles.body.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        helperStyle: AppTextStyles.caption.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: AppTextStyles.caption.copyWith(color: scheme.error),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: _campoBorde(scheme.outline),
        enabledBorder: _campoBorde(scheme.outline),
        focusedBorder: _campoBorde(scheme.primary, 1.8),
        errorBorder: _campoBorde(scheme.error),
        focusedErrorBorder: _campoBorde(scheme.error, 1.8),
        disabledBorder: _campoBorde(scheme.outlineVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _estiloBotonPrimario(scheme, botonShape),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _estiloBotonPrimario(scheme, botonShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurfaceVariant.withValues(alpha: 0.55);
            }
            return scheme.onSurface;
          }),
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          overlayColor: WidgetStatePropertyAll(
            scheme.primary.withValues(alpha: 0.08),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.primary, width: 1.4),
          ),
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          textStyle: const WidgetStatePropertyAll(AppTextStyles.boton),
          shape: WidgetStatePropertyAll(botonShape),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurfaceVariant.withValues(alpha: 0.55);
            }
            return scheme.onSurface;
          }),
          overlayColor: WidgetStatePropertyAll(
            scheme.primary.withValues(alpha: 0.08),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          textStyle: const WidgetStatePropertyAll(AppTextStyles.bodyStrong),
          shape: WidgetStatePropertyAll(botonShape),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.onSurfaceVariant),
          overlayColor: WidgetStatePropertyAll(
            scheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.md),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.xxl),
        ),
        titleTextStyle: AppTextStyles.title.copyWith(color: scheme.onSurface),
        contentTextStyle: AppTextStyles.body.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        modalBackgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        dragHandleColor: scheme.outline,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: AppTextStyles.bodyStrong.copyWith(
          color: scheme.onSurface,
        ),
        subtitleTextStyle: AppTextStyles.caption.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? AppColors.superficieOscuraAlta
            : AppColors.profundoFuerte,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: isDark ? AppColors.textoClaro : AppColors.white,
        ),
        actionTextColor: AppColors.estrella,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.md),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.25),
        selectionHandleColor: scheme.primary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.surfaceContainerHighest,
        labelStyle: AppTextStyles.caption.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: AppTextStyles.caption.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? AppColors.nocheProfunda : AppColors.white;
          }
          return isDark ? AppColors.textoClaroSuave : AppColors.profundoSuave;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return scheme.outline;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.onSurfaceVariant;
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.bodyStrong,
        unselectedLabelStyle: AppTextStyles.bodyStrong.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        textStyle: AppTextStyles.body.copyWith(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.lg),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.superficieOscuraMax
              : AppColors.profundoFuerte,
          borderRadius: AppRadius.circular(AppRadius.sm),
        ),
        textStyle: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.textoClaro : AppColors.white,
        ),
      ),
    );
  }

  static OutlineInputBorder _campoBorde(Color color, [double width = 1.2]) {
    return OutlineInputBorder(
      borderRadius: AppRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static ButtonStyle _estiloBotonPrimario(
    ColorScheme scheme,
    RoundedRectangleBorder shape,
  ) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.surfaceContainerHighest;
        }
        return scheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurfaceVariant.withValues(alpha: 0.65);
        }
        return scheme.onPrimary;
      }),
      overlayColor: WidgetStatePropertyAll(
        scheme.onPrimary.withValues(alpha: 0.08),
      ),
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      textStyle: const WidgetStatePropertyAll(AppTextStyles.boton),
      shape: WidgetStatePropertyAll(shape),
    );
  }
}
