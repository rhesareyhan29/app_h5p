import 'package:flutter/material.dart';

class StudentProfileCard extends StatelessWidget {
  const StudentProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      height: 215,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C4D8A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PROFILE PICTURE
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF00A6FB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),

          // PROFILE INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _ProfileItem(
                  label: 'Nama',
                  value: 'Andi Pratama',
                ),
                SizedBox(height: 12),
                _ProfileItem(
                  label: 'No. Seri',
                  value: 'S123456',
                ),
                SizedBox(height: 12),
                _ProfileItem(
                  label: 'Kelas',
                  value: 'VIII A',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
