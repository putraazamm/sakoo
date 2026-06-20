// lib/views/widgets/child_sakoo_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChildSakooCard extends StatelessWidget {
  final String childNickname;
  final String cardId;
  final String balance;
  final bool isActive;
  final VoidCallback onTap;

  const ChildSakooCard({
    Key? key,
    required this.childNickname,
    required this.cardId,
    required this.balance,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isLinked = cardId.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280, // Ditukar dari 240 ke 280 ikut spesifikasi detail screen
        padding: const EdgeInsets.all(20), // Ditukar dari 16 ke 20
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF252525), Color(0xFF4A4A4A), Color(0xFF1E1E1E)], // Gradient baru
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Logo Sakoo Aligned ke Kanan Atas
            Align(
              alignment: Alignment.topRight,
              child: SvgPicture.asset(
                'lib/assets/images/sakoo-logo-welcome-screen.svg',
                height: 20,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Nama Nickname Anak
            Text(
              childNickname,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16, // Up saiz dari 14 ke 16
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),

            // 3. Card ID / NOT LINKED & Icon Mata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isLinked ? cardId : 'NOT LINKED',
                  style: TextStyle(
                    color: isLinked ? Colors.grey[400] : Colors.white,
                    fontSize: 12,
                    letterSpacing: isLinked ? 1.5 : 0.5,
                  ),
                ),
                Icon(Icons.visibility_outlined, color: Colors.grey[400], size: 18),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Baki Nilai RM & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'RM $balance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24, // Up saiz dari 18 ke 24
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLinked && isActive ? const Color(0xFF1E3A2F) : const Color(0xFF6B6A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isLinked && isActive ? 'ACTIVE' : 'NOT ACTIVE',
                    style: TextStyle(
                      color: isLinked && isActive ? const Color(0xFF6ED7A4) : Colors.yellow[300],
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}