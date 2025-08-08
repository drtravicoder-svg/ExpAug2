import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AllTripsScreenSimple extends StatelessWidget {
  const AllTripsScreenSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('All Trips'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () {
              // Refresh action
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Only one trip can be active at a time',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Active Trip Section
            const Text(
              'Active Trip',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildTripCard(
              title: 'Weekend Getaway',
              dates: 'Dec 15 - Dec 17, 2024',
              members: '4 members',
              totalExpenses: '\$1,247.50',
              status: 'Active',
              statusColor: const Color(0xFF2196F3),
              isActive: true,
            ),
            
            const SizedBox(height: 24),
            
            // Recent Trips Section
            const Text(
              'Recent Trips',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildTripCard(
              title: 'Summer Vacation',
              dates: 'Aug 10 - Aug 20, 2024',
              members: '6 members',
              totalExpenses: '\$3,456.78',
              status: 'Completed',
              statusColor: Colors.green,
              isActive: false,
            ),
            
            const SizedBox(height: 12),
            
            _buildTripCard(
              title: 'Business Conference',
              dates: 'Jul 5 - Jul 7, 2024',
              members: '3 members',
              totalExpenses: '\$892.30',
              status: 'Completed',
              statusColor: Colors.green,
              isActive: false,
            ),
            
            const SizedBox(height: 12),
            
            _buildTripCard(
              title: 'New Year Trip',
              dates: 'Dec 30, 2024 - Jan 2, 2025',
              members: '5 members',
              totalExpenses: '\$0.00',
              status: 'Planning',
              statusColor: Colors.orange,
              isActive: false,
            ),
            
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-trip'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Trip'),
      ),
    );
  }

  Widget _buildTripCard({
    required String title,
    required String dates,
    required String members,
    required String totalExpenses,
    required String status,
    required Color statusColor,
    required bool isActive,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? statusColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? null : Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive 
                    ? Colors.white.withOpacity(0.2)
                    : statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: isActive ? Colors.white : statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isActive)
                Icon(
                  Icons.more_vert,
                  color: Colors.grey[600],
                  size: 20,
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            dates,
            style: TextStyle(
              color: isActive ? Colors.white70 : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Expenses',
                      style: TextStyle(
                        color: isActive ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalExpenses,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Members',
                      style: TextStyle(
                        color: isActive ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      members,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
