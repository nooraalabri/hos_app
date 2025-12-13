// lib/screens/chatbot_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/chatbot_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  ChatRole? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _userRole = ChatRole.patient;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final role = userDoc.data()?['role']?.toString().toLowerCase() ?? 'patient';
      
      ChatRole chatRole;
      switch (role) {
        case 'doctor':
          chatRole = ChatRole.doctor;
          break;
        case 'hospitaladmin':
          chatRole = ChatRole.hospitaladmin;
          break;
        case 'headadmin':
          chatRole = ChatRole.headadmin;
          break;
        default:
          chatRole = ChatRole.patient;
      }

      setState(() {
        _userRole = chatRole;
        _isLoading = false;
      });

      // Add welcome message
      _addBotMessage(ChatMessage(
        text: ChatbotService.getWelcomeMessage(chatRole),
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      setState(() {
        _userRole = ChatRole.patient;
        _isLoading = false;
      });
      _addBotMessage(ChatMessage(
        text: ChatbotService.getWelcomeMessage(ChatRole.patient),
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  void _addBotMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage({String? action, Map<String, dynamic>? actionData}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && action == null || _userRole == null) return;

    if (text.isNotEmpty) {
      _addUserMessage(text);
      _messageController.clear();
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    // Process message (async to fetch from DB)
    try {
      final response = await ChatbotService.processMessage(
        text.isEmpty ? action ?? '' : text,
        _userRole!,
        action: action,
        actionData: actionData,
      );
      setState(() {
        _isLoading = false;
      });
      _addBotMessage(response);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _addBotMessage(ChatMessage(
        text: "Sorry, I encountered an error. Please try again or rephrase your question.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  void _handleDoctorClick(Map<String, dynamic> doctorData) {
    _sendMessage(action: 'select_doctor', actionData: doctorData);
  }

  void _handleTimeSlotClick(Map<String, dynamic> slotData) {
    _sendMessage(action: 'select_timeslot', actionData: slotData);
  }

  void _handleConfirmBooking(Map<String, dynamic> bookingData) {
    _sendMessage(action: 'confirm_booking', actionData: bookingData);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFDDE8EB);
    final darkButtonColor = const Color(0xFF2E4E53);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: darkButtonColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Healthcare Assistant',
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
              children: [
                // Chat messages
                Expanded(
                  child: _isLoading && _messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.smart_toy, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Ask me anything about the app!',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    final message = _messages[index];
                                    return _buildMessageBubble(message, darkButtonColor);
                                  },
                                ),
                                if (_isLoading)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      color: Colors.white.withOpacity(0.9),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 16),
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Thinking...',
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                ),
                // Input area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: darkButtonColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: darkButtonColor.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: darkButtonColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: darkButtonColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Color darkButtonColor) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: darkButtonColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? darkButtonColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message text
                  _buildMessageContent(message, darkButtonColor),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: darkButtonColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person, color: Color(0xFF2E4E53), size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message, Color darkButtonColor) {
    // Handle interactive message types
    if (!message.isUser && message.type != null) {
      switch (message.type) {
        case ChatMessageType.doctorList:
          return _buildDoctorList(message, darkButtonColor);
        case ChatMessageType.timeSlotList:
          return _buildTimeSlotList(message, darkButtonColor);
        case ChatMessageType.bookingConfirmation:
          return _buildBookingConfirmation(message, darkButtonColor);
        default:
          break;
      }
    }

    // Regular text message
    return Text(
      message.text,
      style: TextStyle(
        color: message.isUser ? Colors.white : Colors.black87,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  Widget _buildDoctorList(ChatMessage message, Color darkButtonColor) {
    final doctors = message.data?['doctors'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.text.split('\n\n')[0], // Header text
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...doctors.map((doctor) {
          final doctorData = doctor as Map<String, dynamic>;
          final name = doctorData['doctorName'] ?? 'Unknown';
          final specialization = doctorData['specialization'] ?? '';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _handleDoctorClick(doctorData),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: darkButtonColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: darkButtonColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: darkButtonColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. $name',
                            style: TextStyle(
                              color: darkButtonColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (specialization.isNotEmpty)
                            Text(
                              specialization,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: darkButtonColor, size: 16),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        if (message.text.contains('Total:'))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message.text.split('💡').first.split('Total:').last.trim(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSlotList(ChatMessage message, Color darkButtonColor) {
    final timeSlots = message.data?['timeSlots'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.text.split('\n\n')[0], // Header
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...timeSlots.map((slot) {
          final slotData = slot as Map<String, dynamic>;
          final date = slotData['formattedDate'] ?? '';
          final time = slotData['timeSlot'] ?? '';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _handleTimeSlotClick(slotData),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.green[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$date at $time',
                        style: TextStyle(
                          color: Colors.green[900],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.green[700], size: 16),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBookingConfirmation(ChatMessage message, Color darkButtonColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.text,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleConfirmBooking(message.data ?? {}),
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirm Booking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

