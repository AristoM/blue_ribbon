import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:blue_ribbon/data/services/api_service.dart';
import 'package:blue_ribbon/data/models/photo_verification.dart';

class PhotoVerificationPage extends StatefulWidget {
  final String jobId;
  final String orderName;
  final String modelNumber;

  const PhotoVerificationPage({
    super.key,
    required this.jobId,
    required this.orderName,
    required this.modelNumber,
  });

  @override
  State<PhotoVerificationPage> createState() => _PhotoVerificationPageState();
}

class _PhotoVerificationPageState extends State<PhotoVerificationPage> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  List<PhotoVerificationStep> _steps = [];
  int _currentStepIndex = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSteps();
  }

  Future<void> _fetchSteps() async {
    try {
      final response = await _apiService.getPhotoVerificationSteps(widget.jobId);
      if (response.statusCode == 200 && response.data['success']) {
        final List stepsJson = response.data['data']['steps'] ?? [];
        setState(() {
          _steps = stepsJson.map((j) => PhotoVerificationStep.fromJson(j)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.data['message'] ?? 'Failed to load verification steps';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Mock data if API fails or for initial development
      _loadMockData();
    }
  }

  void _loadMockData() {
    setState(() {
      _steps = [
        PhotoVerificationStep(
          id: '1',
          title: 'Water Line',
          description: 'No kinks, smooth curves',
          referenceImageUrl: 'https://placehold.co/600x400/png?text=Reference+Water+Line',
        ),
        PhotoVerificationStep(
          id: '2',
          title: 'Drain Hose',
          description: 'Secure connection, high loop',
          referenceImageUrl: 'https://placehold.co/600x400/png?text=Reference+Drain+Hose',
        ),
        PhotoVerificationStep(
          id: '3',
          title: 'Door',
          description: 'Level and flush with cabinets',
          referenceImageUrl: 'https://placehold.co/600x400/png?text=Reference+Door',
        ),
        PhotoVerificationStep(
          id: '4',
          title: 'Electrical',
          description: 'Properly grounded, no exposed wires',
          referenceImageUrl: 'https://placehold.co/600x400/png?text=Reference+Electrical',
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _capturePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo == null) return;

    final step = _steps[_currentStepIndex];
    setState(() {
      step.capturedImagePath = photo.path;
      step.status = VerificationStatus.analyzing;
    });

    try {
      final response = await _apiService.verifyPhoto(widget.jobId, step.id, photo.path);
      if (response.statusCode == 200 && response.data['success']) {
        final resultJson = response.data['data'];
        setState(() {
          step.result = PhotoVerificationResult.fromJson(resultJson);
          step.status = step.result!.issueCode != null 
              ? VerificationStatus.issue 
              : VerificationStatus.success;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Analysis failed')),
        );
        setState(() {
          step.status = VerificationStatus.pending;
        });
      }
    } catch (e) {
      // Mock analysis for development
      _mockAnalysis(step);
    }
  }

  void _mockAnalysis(PhotoVerificationStep step) {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        step.result = PhotoVerificationResult(
          confidenceScore: 0.9,
          issueCode: 'DW-W-001',
          issueTitle: 'Kinked Water Line Detected',
          issueDescription: 'The dishwasher drain hose appears to be kinked or sharply bent, which can impede water flow and cause drainage issues.',
          howToFix: [
            'Gently straighten the drain hose to remove any kinks or sharp bends.',
            'Ensure the drain hose has a smooth, unobstructed path to the drain connection.',
            'Verify that the drain hose is not crushed or pinched by any other components.',
          ],
        );
        step.status = VerificationStatus.issue;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Photo Verification',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    _buildTopInfo(),
                    _buildProgressBar(),
                    _buildStepSelector(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _buildCurrentStepContent(),
                      ),
                    ),
                    _buildBottomAction(),
                  ],
                ),
    );
  }

  Widget _buildTopInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Photo Verification',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  'LIVE MODE',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.orderName} • ${widget.modelNumber}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    double progress = (_steps.where((s) => s.status == VerificationStatus.success).length) / _steps.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade100,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          minHeight: 6,
        ),
      ),
    );
  }

  Widget _buildStepSelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _steps.length,
        itemBuilder: (context, index) {
          final step = _steps[index];
          final isSelected = _currentStepIndex == index;

          return GestureDetector(
            onTap: () => setState(() => _currentStepIndex = index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}. ${step.title}',
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    final step = _steps[_currentStepIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          step.description,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildImageCard('REFERENCE', step.referenceImageUrl, isUrl: true)),
            const SizedBox(width: 15),
            Expanded(child: _buildCapturedImageCard(step)),
          ],
        ),
        if (step.status == VerificationStatus.analyzing) _buildAnalyzingState(),
        if (step.status == VerificationStatus.issue) _buildIssueState(step),
        if (step.status == VerificationStatus.success) _buildSuccessState(step),
      ],
    );
  }

  Widget _buildImageCard(String label, String path, {bool isUrl = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isUrl 
                  ? Image.network(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                  : Image.file(File(path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedImageCard(PhotoVerificationStep step) {
    if (step.capturedImagePath == null) {
      return GestureDetector(
        onTap: _capturePhoto,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                'Tap to capture photo',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    String label = 'CURRENT';
    if (step.status == VerificationStatus.issue) label = 'ISSUE';
    if (step.status == VerificationStatus.success) label = 'SUCCESS';

    return Stack(
      children: [
        _buildImageCard(label, step.capturedImagePath!, isUrl: false),
        if (step.status == VerificationStatus.issue)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalyzingState() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'ANALYZING...',
              style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Text('Confidence Score', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.grey,
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text('...', style: TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIssueState(PhotoVerificationStep step) {
    final result = step.result!;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'ISSUE DETECTED',
              style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Text('Confidence Score', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: result.confidenceScore,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${(result.confidenceScore * 100).toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          if (result.issueCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                result.issueCode!,
                style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            result.issueTitle ?? '',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            result.issueDescription ?? '',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 15),
          _buildHowToFix(result.howToFix),
        ],
      ),
    );
  }

  Widget _buildHowToFix(List<String> steps) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 20, color: Colors.orange),
              SizedBox(width: 8),
              Text('How to Fix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entry.key + 1}. ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSuccessState(PhotoVerificationStep step) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text(
            'Verification Success',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    final step = _steps.isEmpty ? null : _steps[_currentStepIndex];
    String label = 'Capture Photo';
    if (step?.status == VerificationStatus.analyzing) label = 'Analyzing...';
    if (step?.status == VerificationStatus.issue) label = 'Capture Fixed';
    if (step?.status == VerificationStatus.success) label = 'Next Step';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: label == 'Analyzing...' ? null : () {
            if (label == 'Next Step') {
              if (_currentStepIndex < _steps.length - 1) {
                setState(() => _currentStepIndex++);
              } else {
                Navigator.pop(context);
              }
            } else {
              _capturePhoto();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
