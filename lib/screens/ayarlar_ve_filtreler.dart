import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool participationFilter = true;
  bool highConfidenceSignals = true;
  bool kapNewsImpact = false;
  bool simpleExplanations = true;

  final Set<String> selectedPatterns = {'Flama', 'Fincan-Kulp'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildResearchMode(context),
                      const SizedBox(height: 28),
                      _buildDefaultSignals(context),
                      const SizedBox(height: 28),
                      _buildPatternPreferences(context),
                      const SizedBox(height: 28),
                      _buildExplanationLevel(context),
                      const SizedBox(height: 28),
                      _buildCurrentSummary(context),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -52,
            top: -72,
            child: _glow(
              color: colors.primary.withValues(alpha: .10),
              size: 176,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ARAŞTIRMA KOKPİTİ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ayarlar ve Filtreler',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                      ),
                    ),
                  ],
                ),
              ),
              _iconButton(
                context,
                icon: Icons.help_outline_rounded,
                onPressed: () {},
                semanticLabel: 'Ayar bilgileri',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResearchMode(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _section(
      context,
      eyebrow: 'Kişisel filtre',
      title: 'Araştırma Modu',
      child: Container(
        clipBehavior: Clip.hardEdge,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.primary.withValues(alpha: .45)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: .15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -36,
              top: -52,
              child: _glow(
                color: colors.primary.withValues(alpha: .15),
                size: 144,
              ),
            ),
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _coloredIcon(
                      context,
                      Icons.verified_user_outlined,
                      background: colors.primary,
                      foreground: colors.onPrimary,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sadece Katılım Endeksine Uygun Hisseleri Göster',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Faizsiz yatırım hassasiyetine uygun hisseler dışındaki sonuçlar gizlenir.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    height: 1.65,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _switch(
                            context,
                            value: participationFilter,
                            onChanged: (value) {
                              setState(() => participationFilter = value);
                            },
                            semanticLabel: 'Katılım Endeksi filtresi',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _statusLine(
                  context,
                  text: 'Ana Sayfa, arama ve formasyonlar için etkin',
                  borderColor: colors.primary.withValues(alpha: .20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultSignals(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _section(
      context,
      eyebrow: 'Önceliklendirme',
      title: 'Varsayılan Sinyaller',
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            _settingRow(
              context,
              icon: Icons.verified_outlined,
              iconColor: colors.primary,
              title: 'Yalnızca yüksek güvenli formasyonlar',
              description: 'Güven puanı güçlü sinyaller önce görünür.',
              value: highConfidenceSignals,
              onChanged: (value) {
                setState(() => highConfidenceSignals = value);
              },
              semanticLabel: 'Yüksek güvenli formasyonlar',
            ),
            Divider(height: 1, indent: 16, endIndent: 16, color: colors.outlineVariant),
            _settingRow(
              context,
              icon: Icons.newspaper_outlined,
              iconColor: colors.tertiary,
              title: 'KAP haber etkisini göster',
              description: 'Şirket duyurularının olası etkisini sade özetle gör.',
              value: kapNewsImpact,
              onChanged: (value) {
                setState(() => kapNewsImpact = value);
              },
              semanticLabel: 'KAP haber etkisi',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternPreferences(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _section(
      context,
      eyebrow: 'Görünüm seçimi',
      title: 'Formasyon Tercihleri',
      description: 'Seçtiklerin Formasyonlar ekranında öne çıkar.',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _patternChip(context, 'Flama'),
                _patternChip(context, 'Fincan-Kulp'),
                _patternChip(context, 'Ters Omuz-Baş-Omuz'),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: colors.outlineVariant),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 17, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Formasyonlar bir kesinlik değil, araştırmayı düzenleyen işaretlerdir.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationLevel(BuildContext context) {
    return _section(
      context,
      eyebrow: 'Okuma deneyimi',
      title: 'Anlatım Seviyesi',
      child: Row(
        children: [
          Expanded(
            child: _explanationCard(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Sade açıklamalar',
              description: 'Başlangıç için net ve kısa yorumlar.',
              selected: simpleExplanations,
              onTap: () => setState(() => simpleExplanations = true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _explanationCard(
              context,
              icon: Icons.bar_chart_rounded,
              title: 'Detaylı metrikler',
              description: 'Araştırmada ek yöntem etiketleri göster.',
              selected: !simpleExplanations,
              onTap: () => setState(() => simpleExplanations = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSummary(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _coloredIcon(
            context,
            Icons.check_circle_outline_rounded,
            background: colors.primary.withValues(alpha: .18),
            foreground: colors.primary,
            size: 40,
            iconSize: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GEÇERLİ KURULUM',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Katılım filtresi açık · Yüksek güvenli sinyaller öncelikli',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tercihlerin araştırma ekranlarına anında uygulanır.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _patternChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = selectedPatterns.contains(label);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          setState(() {
            if (selected) {
              selectedPatterns.remove(label);
            } else {
              selectedPatterns.add(label);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: .15)
                : colors.secondaryContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: .40)
                  : colors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                CircleAvatar(
                  radius: 8,
                  backgroundColor: colors.primary,
                  child: Icon(Icons.check, size: 11, color: colors.onPrimary),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? colors.primary : colors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _explanationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 158),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: .12)
                : colors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: .45)
                  : colors.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _coloredIcon(
                    context,
                    icon,
                    background: selected
                        ? colors.primary
                        : colors.secondaryContainer,
                    foreground: selected
                        ? colors.onPrimary
                        : colors.onSecondaryContainer,
                    size: 32,
                    iconSize: 17,
                  ),
                  if (selected)
                    _coloredIcon(
                      context,
                      Icons.check,
                      background: colors.primary,
                      foreground: colors.onPrimary,
                      size: 20,
                      iconSize: 13,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String semanticLabel,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _coloredIcon(
            context,
            icon,
            background: iconColor.withValues(alpha: .12),
            foreground: iconColor,
            size: 40,
            iconSize: 19,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _switch(
            context,
            value: value,
            onChanged: onChanged,
            semanticLabel: semanticLabel,
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String eyebrow,
    required String title,
    String? description,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _statusLine(
    BuildContext context, {
    required String text,
    required Color borderColor,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          _coloredIcon(
            context,
            Icons.check,
            background: colors.primary.withValues(alpha: .15),
            foreground: colors.primary,
            size: 20,
            iconSize: 13,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switch(
    BuildContext context, {
    required bool value,
    required ValueChanged<bool> onChanged,
    required String semanticLabel,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: semanticLabel,
      toggled: value,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: value ? colors.primary : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: value ? null : Border.all(color: colors.outline),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? colors.onPrimary : colors.onSurfaceVariant,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: .20),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _coloredIcon(
    BuildContext context,
    IconData icon, {
    required Color background,
    required Color foreground,
    required double size,
    double iconSize = 20,
  }) {
    final rounded = size == 44;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: rounded ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: rounded ? BorderRadius.circular(12) : null,
      ),
      child: Icon(icon, size: iconSize, color: foreground),
    );
  }

  Widget _iconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String semanticLabel,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Icon(icon, color: colors.onSecondaryContainer),
          ),
        ),
      ),
    );
  }

  Widget _glow({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}