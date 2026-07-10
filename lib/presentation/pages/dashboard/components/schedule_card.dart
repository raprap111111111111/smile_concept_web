import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';


class ScheduleCard extends StatelessWidget {
  final List<dynamic> appointments;

  const ScheduleCard(this.appointments, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Schedule",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Book New'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (appointments.isEmpty)
            const Center(child: Text('No appointments today', style: TextStyle(color: Colors.white70)))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appt = appointments[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(appt['time'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                  title: Text(appt['patientName'] ?? 'Unknown Patient'),
                  subtitle: Text(appt['type'] ?? ''),
                );
              },
            ),
        ],
      ),
    );
  }
}