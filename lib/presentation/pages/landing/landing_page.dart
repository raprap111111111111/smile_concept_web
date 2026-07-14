import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../route/route_names.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const _ink = Color(0xFF12313A);
  static const _muted = Color(0xFF5F7480);
  static const _line = Color(0xFFDDE9ED);
  static const _surface = Color(0xFFF7FBFC);
  static const _primary = Color(0xFF0E8FA3);
  static const _primaryDark = Color(0xFF096577);
  static const _accent = Color(0xFF8BCBC1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Navigation(onBook: () => _book(context)),
            _HeroSection(onBook: () => _book(context)),
            const _TrustStrip(),
            const _ServicesSection(),
            const _CareSection(),
            _AppointmentSection(onBook: () => _book(context)),
            const _Footer(),
          ],
        ),
      ),
    );
  }

  void _book(BuildContext context) {
    context.pushNamed(RouteNames.register);
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: LandingPage._line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 760;

                return Wrap(
                  spacing: 18,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/smile.jpg',
                            height: 44,
                            width: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'SmileConcept',
                          style: TextStyle(
                            color: LandingPage._ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (!isCompact)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _NavLink(label: 'Services'),
                          _NavLink(label: 'Doctors'),
                          _NavLink(label: 'Care'),
                          _NavLink(label: 'Contact'),
                        ],
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => context.pushNamed(RouteNames.login),
                          child: const Text('Login'),
                        ),
                        const SizedBox(width: 8),
                        _PrimaryButton(
                            label: 'Book an appointment', onTap: onBook),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LandingPage._surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 860;
                final content = _HeroCopy(onBook: onBook);
                final image = const _HeroImage();

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      content,
                      const SizedBox(height: 32),
                      image,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 52),
                    Expanded(child: image),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Pill(text: 'Modern family dental clinic'),
        const SizedBox(height: 22),
        const Text(
          'Confident smiles start with calm, expert care.',
          style: TextStyle(
            color: LandingPage._ink,
            fontSize: 56,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'SmileConcept combines preventive dentistry, cosmetic treatments, and simple online booking in one welcoming clinic experience.',
          style: TextStyle(
            color: LandingPage._muted,
            fontSize: 18,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _PrimaryButton(label: 'Book an appointment', onTap: onBook),
            OutlinedButton.icon(
              onPressed: () => context.pushNamed(RouteNames.login),
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('Patient login'),
              style: OutlinedButton.styleFrom(
                foregroundColor: LandingPage._primaryDark,
                side: const BorderSide(color: LandingPage._line),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.04,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?w=1400',
              fit: BoxFit.cover,
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LandingPage._line),
                ),
                child: const Row(
                  children: [
                    _IconBadge(icon: Icons.verified_outlined),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Gentle treatment planning for every age and smile goal.',
                        style: TextStyle(
                          color: LandingPage._ink,
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              children: const [
                _TrustItem(value: '24/7', label: 'online scheduling'),
                _TrustItem(value: '15+', label: 'dental services'),
                _TrustItem(value: 'Secure', label: 'patient records'),
                _TrustItem(value: 'Clear', label: 'treatment estimates'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection();

  @override
  Widget build(BuildContext context) {
    final services = [
      const _ServiceCard(
        icon: Icons.health_and_safety_outlined,
        title: 'Preventive Care',
        body:
            'Routine checkups, cleanings, oral exams, and gum health support.',
      ),
      const _ServiceCard(
        icon: Icons.auto_awesome_outlined,
        title: 'Cosmetic Dentistry',
        body:
            'Whitening, veneers, and smile design with natural-looking results.',
      ),
      const _ServiceCard(
        icon: Icons.straighten_outlined,
        title: 'Alignment',
        body:
            'Modern orthodontic options for healthier bite and cleaner smiles.',
      ),
      const _ServiceCard(
        icon: Icons.medical_services_outlined,
        title: 'Restorative Dentistry',
        body: 'Crowns, fillings, and treatment plans that restore comfort.',
      ),
    ];

    return _Section(
      title: 'Complete dental care, thoughtfully organized',
      body:
          'Clear services, gentle communication, and a clinic workflow designed around patient comfort.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 720 ? 1 : 4;

          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: columns == 1 ? 3.2 : 0.88,
            children: services,
          );
        },
      ),
    );
  }
}

class _CareSection extends StatelessWidget {
  const _CareSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LandingPage._surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 820;

                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Pill(text: 'Patient-first experience'),
                    SizedBox(height: 18),
                    Text(
                      'A calmer visit from booking to follow-up.',
                      style: TextStyle(
                        color: LandingPage._ink,
                        fontSize: 36,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'The landing experience now reflects what patients expect from a professional dental clinic: clarity, trust, fast action, and reassurance before they book.',
                      style: TextStyle(
                        color: LandingPage._muted,
                        fontSize: 16,
                        height: 1.65,
                      ),
                    ),
                  ],
                );

                final list = Column(
                  children: const [
                    _CarePoint(
                      icon: Icons.event_available_outlined,
                      title: 'Simple appointment flow',
                      body:
                          'A direct booking CTA appears in the header, hero, and final section.',
                    ),
                    _CarePoint(
                      icon: Icons.description_outlined,
                      title: 'Transparent treatment planning',
                      body:
                          'Patients can understand services before creating an account.',
                    ),
                    _CarePoint(
                      icon: Icons.notifications_active_outlined,
                      title: 'Helpful reminders',
                      body:
                          'A clean bridge into the patient portal and clinic management system.',
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      content,
                      const SizedBox(height: 30),
                      list,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 48),
                    Expanded(child: list),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentSection extends StatelessWidget {
  const _AppointmentSection({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LandingPage._primaryDark,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 58),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const SizedBox(
                  width: 620,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready for your next dental visit?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Book an appointment and let the team prepare a smooth, personal visit.',
                        style: TextStyle(
                          color: Color(0xFFD7F1F3),
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onBook,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Book an appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: LandingPage._primaryDark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                Text(
                  'SmileConcept Dental',
                  style: TextStyle(
                    color: LandingPage._ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Modern care for healthier, brighter smiles.',
                  style: TextStyle(color: LandingPage._muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.body,
    required this.child,
  });

  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 680,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: LandingPage._ink,
                        fontSize: 38,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      body,
                      style: const TextStyle(
                        color: LandingPage._muted,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LandingPage._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconBadge(icon: icon),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: LandingPage._ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: LandingPage._muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarePoint extends StatelessWidget {
  const _CarePoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LandingPage._line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: LandingPage._ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  style: const TextStyle(
                    color: LandingPage._muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Row(
        children: [
          const _IconBadge(icon: Icons.check_circle_outline),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: LandingPage._ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, style: const TextStyle(color: LandingPage._muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_month_outlined, size: 19),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: LandingPage._primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: LandingPage._muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: LandingPage._accent.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LandingPage._accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: LandingPage._primaryDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: LandingPage._accent.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: LandingPage._primaryDark, size: 23),
    );
  }
}
