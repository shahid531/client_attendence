import 'package:flutter/material.dart';

// class RequestPage extends StatefulWidget {
//   const RequestPage({super.key});
//
//   @override
//   State<RequestPage> createState() => _RequestPageState();
// }
//
// class _RequestPageState extends State<RequestPage> {
//   @override
//   void initState() {
//     super.initState();
//     context.read<LeaveBloc>().add(LoadLeaveRequestsEvent());
//   }
//
//   void _showNewRequestDialog() {
//     final titleController = TextEditingController();
//     final reasonController = TextEditingController();
//     String selectedType = 'Leave';
//     DateTime startDate = DateTime.now();
//     DateTime endDate = DateTime.now().add(const Duration(days: 1));
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) {
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             return Padding(
//               padding: EdgeInsets.only(
//                 left: 20,
//                 right: 20,
//                 top: 20,
//                 bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'New Attendance Request',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.textDark,
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () => Navigator.pop(ctx),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: titleController,
//                     decoration: const InputDecoration(
//                       labelText: 'Title / Subject',
//                       hintText: 'e.g. Annual Vacation Leave',
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   DropdownButtonFormField<String>(
//                     initialValue: selectedType,
//                     decoration: const InputDecoration(labelText: 'Request Type'),
//                     items: ['Leave', 'Attendance Adjustment'].map((type) {
//                       return DropdownMenuItem(value: type, child: Text(type));
//                     }).toList(),
//                     onChanged: (val) {
//                       if (val != null) setModalState(() => selectedType = val);
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   TextField(
//                     controller: reasonController,
//                     maxLines: 3,
//                     decoration: const InputDecoration(
//                       labelText: 'Reason & Details',
//                       hintText: 'Provide context for your manager...',
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 48,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         if (titleController.text.trim().isEmpty) return;
//                         context.read<LeaveBloc>().add(
//                               SubmitLeaveRequestEvent(
//                                 title: titleController.text.trim(),
//                                 requestType: selectedType,
//                                 startDate: startDate,
//                                 endDate: endDate,
//                                 reason: reasonController.text.trim(),
//                               ),
//                             );
//                         Navigator.pop(ctx);
//                       },
//                       child: const Text('Submit Request'),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _showNewRequestDialog,
//         backgroundColor: AppColors.primaryNavy,
//         icon: const Icon(Icons.add, color: Colors.white),
//         label: const Text('New Request', style: TextStyle(color: Colors.white)),
//       ),
//       body: BlocConsumer<LeaveBloc, LeaveState>(
//         listener: (context, state) {
//           if (state is LeaveLoadedState && state.successMessage != null) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.successMessage!),
//                 backgroundColor: AppColors.successEmerald,
//               ),
//             );
//           }
//         },
//         builder: (context, state) {
//           if (state is LeaveLoadingState) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           final requests = state is LeaveLoadedState ? state.requests : [];
//
//           if (requests.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: const [
//                   Icon(Icons.note_alt_outlined, size: 48, color: AppColors.textLight),
//                   SizedBox(height: 12),
//                   Text(
//                     'No pending or completed requests',
//                     style: TextStyle(color: AppColors.textMuted, fontSize: 16),
//                   ),
//                 ],
//               ),
//             );
//           }
//
//           return ListView.separated(
//             padding: const EdgeInsets.all(16),
//             itemCount: requests.length,
//             separatorBuilder: (_, __) => const SizedBox(height: 12),
//             itemBuilder: (context, index) {
//               final item = requests[index];
//               return _buildRequestCard(item);
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildRequestCard(LeaveRequest item) {
//     final startStr = DateFormat('MMM dd, yyyy').format(item.startDate);
//     final endStr = DateFormat('MMM dd, yyyy').format(item.endDate);
//
//     Color statusColor = AppColors.warningAmber;
//     Color statusBg = AppColors.warningBg;
//     if (item.status == 'Approved') {
//       statusColor = AppColors.successEmerald;
//       statusBg = AppColors.successBg;
//     } else if (item.status == 'Rejected') {
//       statusColor = AppColors.dangerRose;
//       statusBg = AppColors.dangerBg;
//     }
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppColors.borderGrey),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   item.title,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                     color: AppColors.textDark,
//                   ),
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: statusBg,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   item.status,
//                   style: TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.bold,
//                     color: statusColor,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '${item.requestType} • $startStr to $endStr',
//             style: const TextStyle(
//               fontSize: 13,
//               color: AppColors.textMuted,
//             ),
//           ),
//           if (item.reason.isNotEmpty) ...[
//             const SizedBox(height: 8),
//             Text(
//               item.reason,
//               style: const TextStyle(
//                 fontSize: 13,
//                 color: AppColors.textDark,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

//----------------------------------------------------------------------------------------


class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestPage> {
  int _selectedTabIndex = 0; // 0 for Pending, 1 for Completed

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Title
          const Text(
            'Requests',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // Segmented Tab Toggle (Pending / Completed)
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _selectedTabIndex == 0
                            ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Pending (2)',
                        style: TextStyle(
                          color: _selectedTabIndex == 0
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF64748B),
                          fontWeight: _selectedTabIndex == 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _selectedTabIndex == 1
                            ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Completed',
                        style: TextStyle(
                          color: _selectedTabIndex == 1
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF64748B),
                          fontWeight: _selectedTabIndex == 1
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab View Content
          if (_selectedTabIndex == 0) ...[
            // Card 1: Attendance Regularization
            _buildRequestCard(
              icon: Icons.access_time_outlined,
              title: 'Attendance Regularization',
              date: 'Oct 12, 2023',
              timeDetails: 'In: 08:55 AM    Out: 05:05 PM',
              description:
              'Forgot to clock in during the morning rush. Was at my desk by 8:55 AM.',
            ),
            const SizedBox(height: 12),

            // Card 2: Work From Home
            _buildRequestCard(
              icon: Icons.other_houses_outlined,
              title: 'Work From Home',
              date: 'Oct 15 - Oct 16',
              description:
              'Plumbing emergency at home, need to be present for repairs.',
            ),
          ] else ...[
            // Empty or completed state view
            const Center(

              child: Text(
                'No completed requests found.',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Request Item Card Builder
  Widget _buildRequestCard({
    required IconData icon,
    required String title,
    required String date,
    String? timeDetails,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF1E293B),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            date,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          if (timeDetails != null) ...[
            const SizedBox(height: 6),
            Text(
              timeDetails,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}