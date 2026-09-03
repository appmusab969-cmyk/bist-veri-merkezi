import 'package:flutter/material.dart';

class AselsAnalysisScreen extends StatefulWidget {
  const AselsAnalysisScreen({super.key});

  @override
  State<AselsAnalysisScreen> createState() => _AselsAnalysisScreenState();
}

class _AselsAnalysisScreenState extends State<AselsAnalysisScreen> {
  int _selectedTab = 0;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  TextTheme get _textTheme => Theme.of(context).textTheme;

  TextStyle get _heading => (_textTheme.headlineSmall ?? const TextStyle()).copyWith(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w700,
        color: _colors.onSurface,
      );

  TextStyle get _body => (_textTheme.bodyMedium ?? const TextStyle()).copyWith(
        fontFamily: 'Inter',
        color: _colors.onSurface,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colors.surface,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 116),
              children: [
                _buildIntro(),
                const SizedBox(height: 14),
                _buildPiotroskiCard(),
                const SizedBox(height: 14),
                _buildAltmanCard(),
                const SizedBox(height: 14),
                _buildDupontCard(),
                const SizedBox(height: 22),
                _buildSupportingSection(),
                const SizedBox(height: 16),
                _buildDisclaimer(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildAlertBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      decoration: BoxDecoration(
        color: _colors.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: _colors.outlineVariant)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconButton(Icons.arrow_back, 'Geri dön', () => Navigator.maybePop(context)),
              Column(
                children: [
                  Text(
                    'PRO ANALİZ',
                    style: _body.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: _colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('ASELS', style: _heading.copyWith(fontSize: 18)),
                ],
              ),
              _iconButton(Icons.more_horiz, 'Daha fazla seçenek', () {}),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '305,50 TL',
                          style: _heading.copyWith(
                            fontSize: 20,
                            color: _colors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _pill('Katılım', _colors.primary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aselsan Elektronik Sanayi ve Ticaret A.Ş.',
                      style: _body.copyWith(
                        fontSize: 12,
                        color: _colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Son güncelleme',
                    style: _body.copyWith(fontSize: 12, color: _colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '18 Haz 2024',
                    style: _body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _colors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String label, VoidCallback onPressed) {
    return Semantics(
      label: label,
      button: true,
      child: SizedBox(
        width: 40,
        height: 40,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: _colors.surfaceContainer,
            side: BorderSide(color: _colors.outlineVariant),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Icon(icon, size: 20, color: _colors.onSurface),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    const labels = [
      'Özet Kokpit',
      'Pro Analiz',
      'Rasyolar & 10 Yıllık',
      'Bilanço & Risk',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: _colors.surface.withValues(alpha: .95),
        border: Border(bottom: BorderSide(color: _colors.outlineVariant)),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _colors.surfaceContainer,
          border: Border.all(color: _colors.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = _selectedTab == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? _colors.primary.withValues(alpha: .15) : null,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: _body.copyWith(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? _colors.primary : _colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KURUMSAL SAĞLIK',
              style: _body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                color: _colors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text('Sayıların sakin okuması', style: _heading.copyWith(fontSize: 20)),
          ],
        ),
        Row(
          children: [
            Icon(Icons.schedule, size: 15, color: _colors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'Yıllık veriler',
              style: _body.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card({required Widget child, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? _colors.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: _body.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildPiotroskiCard() {
    return Semantics(
      button: true,
      label: 'Piotroski F-Skoru ayrıntıları',
      child: GestureDetector(
        onTap: () {},
        child: _card(
          borderColor: _colors.primary.withValues(alpha: .3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _colors.primary.withValues(alpha: .15),
                    child: Icon(Icons.verified, color: _colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _eyebrow('PIOTROSKI F-SKORU'),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            text: '8',
                            style: _heading.copyWith(fontSize: 24),
                            children: [
                              TextSpan(
                                text: '/9',
                                style: _body.copyWith(
                                  fontSize: 14,
                                  color: _colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _pill('Çok Güçlü', _colors.primary),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down, color: _colors.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'ASELS kârlılık, borçluluk ve nakit üretimi açısından güçlü bir finansal yapı sergiliyor.',
                style: _body.copyWith(fontSize: 14, height: 1.4, color: _colors.onSurface),
              ),
              const SizedBox(height: 14),
              _cardFooter('9 kriteri ayrıntılı incele', 'Açıklamayı gör'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eyebrow(String text) {
    return Text(
      text,
      style: _body.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: _colors.onSurfaceVariant,
      ),
    );
  }

  Widget _cardFooter(String left, String right) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _colors.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: _body.copyWith(fontSize: 12, color: _colors.onSurfaceVariant)),
          Row(
            children: [
              Text(
                right,
                style: _body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _colors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 15, color: _colors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAltmanCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _eyebrow('ALTMAN Z-SKORU'),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('3,45', style: _heading.copyWith(fontSize: 26)),
                        const SizedBox(width: 8),
                        Text(
                          'Güvenli Bölge',
                          style: _body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: _colors.primary.withValues(alpha: .1),
                child: Icon(Icons.shield, size: 19, color: _colors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bu skor, şirketin kısa vadede finansal sıkıntı yaşama ihtimalinin düşük olduğunu anlatır.',
            style: _body.copyWith(fontSize: 12, height: 1.35, color: _colors.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          _buildRiskBar(),
        ],
      ),
    );
  }

  Widget _buildRiskBar() {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Expanded(flex: 27, child: Container(height: 12, color: _colors.error)),
                      Expanded(flex: 25, child: Container(height: 12, color: _colors.tertiary)),
                      Expanded(flex: 48, child: Container(height: 12, color: _colors.primary)),
                    ],
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * .76 - 2,
                  top: -4,
                  child: Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _colors.onSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['Riskli', 'Dikkat', 'Güvenli']
              .map((label) => Text(
                    label,
                    style: _body.copyWith(fontSize: 10, color: _colors.onSurfaceVariant),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDupontCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _eyebrow('DUPONT ÖZKAYNAK KÂRLILIĞI'),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('%38,2', style: _heading.copyWith(fontSize: 26)),
                        const SizedBox(width: 8),
                        Text(
                          'Güçlü',
                          style: _body.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _colors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Şirket, ortakların sermayesini yüksek verimle kâra dönüştürüyor.',
            style: _body.copyWith(fontSize: 12, height: 1.35, color: _colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _factor('%18,0', 'Net kâr marjı', _colors.primary),
              _operator(),
              _factor('0,85x', 'Aktif devir hızı', _colors.onSurface),
              _operator(),
              _factor('2,49x', 'Kaldıraç çarpanı', _colors.tertiary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _operator() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Text('×', style: _body.copyWith(fontSize: 12, color: _colors.onSurfaceVariant)),
      );

  Widget _factor(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          children: [
            Text(value, style: _heading.copyWith(fontSize: 14, color: color)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: _body.copyWith(fontSize: 9, height: 1.2, color: _colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportingSection() {
    final metrics = [
      (Icons.account_balance_wallet, '%118', 'Serbest Nakit / Net Kâr', 'Kârın üzerinde nakit üretimi', _colors.primary),
      (Icons.factory, '%88', 'Esas Faaliyet Kârı Payı', 'Kârın ana işten gelme oranı', _colors.primary),
      (Icons.trending_up, '+%14,2', 'Yıllık Reel Büyüme', 'Enflasyondan arındırılmış artış', _colors.tertiary),
      (Icons.percent, '%29,4', 'ROIC', 'Yatırılan sermayenin getirisi', _colors.primary),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESTEKLEYİCİ GÖSTERGELER',
                  style: _body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: _colors.tertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Nakit ve verimlilik', style: _heading.copyWith(fontSize: 18)),
              ],
            ),
            Text('2023 → 2024', style: _body.copyWith(fontSize: 10, color: _colors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .95,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return _metricCard(
              icon: metric.$1,
              value: metric.$2,
              title: metric.$3,
              description: metric.$4,
              color: metric.$5,
            );
          },
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String value,
    required String title,
    required String description,
    required Color color,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 19, color: color),
              Icon(Icons.north_east, size: 15, color: _colors.onSurfaceVariant),
            ],
          ),
          const Spacer(),
          Text(value, style: _heading.copyWith(fontSize: 22, color: color == _colors.primary ? _colors.onSurface : color)),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: _colors.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _body.copyWith(fontSize: 10, height: 1.25, color: _colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 19, color: _colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Göstergeler geçmiş finansal verilere dayanır. Tek başına alım veya satım önerisi değildir; her kartta sektör kıyasını ve tarihsel görünümü ayrıca inceleyebilirsin.',
              style: _body.copyWith(fontSize: 12, height: 1.35, color: _colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: _colors.surface.withValues(alpha: .97),
          border: Border(top: BorderSide(color: _colors.primary.withValues(alpha: .3))),
        ),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, size: 19),
            label: const Text('ASELS için uyarı oluştur'),
            style: FilledButton.styleFrom(
              backgroundColor: _colors.primary,
              foregroundColor: _colors.onPrimary,
              textStyle: _body.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}