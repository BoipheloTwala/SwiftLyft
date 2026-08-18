import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/driver.dart';

/// Card displaying driver information with contact options
class DriverInfoCard extends StatelessWidget {
  final Driver driver;
  final String? vehicleInfo;

  const DriverInfoCard({
    super.key,
    required this.driver,
    this.vehicleInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Driver photo
                CircleAvatar(
                  radius: 30,
                  backgroundImage: driver.photoUrl != null
                      ? NetworkImage(driver.photoUrl!)
                      : null,
                  child: driver.photoUrl == null
                      ? Text(
                          driver.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Driver info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 4),
                          Text(
                            driver.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${driver.totalTrips} trips',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Contact buttons
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _makePhoneCall(driver.phone),
                      icon: const Icon(Icons.phone),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: () => _sendSMS(driver.phone),
                      icon: const Icon(Icons.message),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Vehicle info
            if (vehicleInfo != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.directions_car, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    vehicleInfo!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final uri = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

/// Compact driver info bar
class DriverInfoBar extends StatelessWidget {
  final Driver driver;
  final VoidCallback? onTap;

  const DriverInfoBar({
    super.key,
    required this.driver,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: driver.photoUrl != null
                  ? NetworkImage(driver.photoUrl!)
                  : null,
              child: driver.photoUrl == null
                  ? Text(
                      driver.name[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    driver.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        driver.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _makePhoneCall(driver.phone),
              icon: const Icon(Icons.phone),
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                foregroundColor: Colors.green.shade700,
              ),
            ),
            if (onTap != null)
              Icon(Icons.expand_less, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

