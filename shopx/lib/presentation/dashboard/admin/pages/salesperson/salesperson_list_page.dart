import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/salesman/salesman_notifier.dart';
import 'package:shopx/presentation/dashboard/admin/pages/salesperson/add_salesperson_page.dart';




class SalespersonListPage extends HookConsumerWidget {
  const SalespersonListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {


    // Watch the Salesman State (Loading, List, Error)
    final salesmanState = ref.watch(salesmanNotifierProvider);

    // Fetch data once when page mounts
    useEffect(() {
      Future.microtask(() {
        ref.read(salesmanNotifierProvider.notifier).fetchSalesmen();
      });
      return null;
    }, []);

    // Local State for Search Text
    final searchController = useTextEditingController();
    final searchText = useState("");

    // Listener for search text changes
    useEffect(() {
      void listener() => searchText.value = searchController.text;
      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    // Local State to track which card is expanded (Modify/Delete view)
    // Using int? assuming ID is int, or String? if ID is string.
    // Based on prompt "final int? id", using int?.
    final expandedId = useState<int?>(null);

    // -------------------------------------------------------------------------
    // 2. LOGIC (Filter)
    // -------------------------------------------------------------------------
    
    final filteredSalesmen = salesmanState.salesmen.where((salesman) {
      if (searchText.value.isEmpty) return true;
      final query = searchText.value.toLowerCase();
      return salesman.username.toLowerCase().contains(query) ||
             salesman.phone.toLowerCase().contains(query) ||
             salesman.email.toLowerCase().contains(query);
    }).toList();

    // -------------------------------------------------------------------------
    // 3. STYLES
    // -------------------------------------------------------------------------
    const primaryBlue = Color(0xFF1E75D5); // Matches design #1E75D5
    const deleteRed = Color(0xFFEF3838);   // Matches design red
    const bgGrey = Color(0xFFF8F9FB);      // Light grey background
    const textDark = Color(0xFF1D1D1D);
    const textGrey = Color(0xFF888888);

    // -------------------------------------------------------------------------
    // 4. UI BUILD
    // -------------------------------------------------------------------------
    return Scaffold(
     backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryBlue, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Salesman",
          style: TextStyle(
            color: primaryBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Content
          Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(salesmanNotifierProvider.notifier).fetchSalesmen();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),

                        // --- Search Bar ---
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: "Search for a salesman",
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              suffixIcon: Icon(Icons.search, color: textDark),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- Loading State ---
                        if (salesmanState.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30.0),
                              child: CircularProgressIndicator(color: primaryBlue),
                            ),
                          ),

                        // --- Error State ---
                        if (salesmanState.error != null && !salesmanState.isLoading)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                "Error: ${salesmanState.error}",
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),

                        // --- Empty State ---
                        if (!salesmanState.isLoading && filteredSalesmen.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 50.0),
                              child: Text(
                                "No salesmen found",
                                style: TextStyle(color: textGrey),
                              ),
                            ),
                          ),

                        // --- List Items ---
                        ...filteredSalesmen.map((salesman) {
                          final isExpanded = expandedId.value == salesman.id;

                          return GestureDetector(
                            onTap: () {
                              // Toggle Expand
                              if (isExpanded) {
                                expandedId.value = null;
                              } else {
                                expandedId.value = salesman.id;
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name
                                  Text(
                                    salesman.username,
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Phone
                                  Text(
                                    salesman.phone,
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 14,
                                    ),
                                  ),

                                  // --- Expanded Content ---
                                  if (isExpanded) ...[
                                    const SizedBox(height: 4),
                                    // Email
                                    Text(
                                      salesman.email,
                                      style: const TextStyle(
                                        color: textDark,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Action Buttons
                                    Row(
                                      children: [
                                        // Modify Button
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                // Navigate to Edit Page
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => AddSalespersonPage(salesman: salesman),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryBlue,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                "Modify",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Delete Button
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                _showDeleteDialog(context, ref, salesman);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: deleteRed,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                "Delete",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        // Spacer for bottom button
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --- Bottom Add Button ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: bgGrey, // Blend with background
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Add Page (No salesman passed means Create mode)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddSalespersonPage(salesman: null),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 4,
                    shadowColor: primaryBlue.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Add Salesman",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showDeleteDialog(BuildContext context, WidgetRef ref, dynamic salesman) {
    
    showDialog(
      
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Delete Salesman"),
        content: Text("Are you sure you want to delete ${salesman.username}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (salesman.id != null) {
                ref.read(salesmanNotifierProvider.notifier).deleteSalesman(salesman.id!);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}