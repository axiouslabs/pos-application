import 'package:shopx/domain/customers/customer.dart';
import 'package:shopx/infrastructure/customers/customer_api.dart';

class CustomerRepository {
  final CustomerApi api;

  CustomerRepository(this.api);

  // CREATE
  Future<Customer> createCustomer(Customer customer) async {
    final res = await api.createCustomer(customer.toJson());
    return Customer.fromJson(res);
  }

  
// ALL customers (Cart)
Future<List<Customer>> getAllCustomers() async {
  final res = await api.getCustomers();
  return res.map<Customer>((json) => Customer.fromJson(json)).toList();
}

// ONLY logged-in salesperson customers (Manage Customers)
Future<List<Customer>> getMyCustomers() async {
  final res = await api.getMyCustomers();
  return res.map<Customer>((json) => Customer.fromJson(json)).toList();
}


  // GET SINGLE
  Future<Customer> getCustomerById(int id) async {
    final json = await api.getCustomerById(id);
    return Customer.fromJson(json);
  }

  // UPDATE
  Future<Customer> updateCustomer(int id, Customer customer) async {
    final res = await api.updateCustomer(id, customer.toJson());
    return Customer.fromJson(res);
  }

  // DELETE
  Future<void> deleteCustomer(int id) async {
    await api.deleteCustomer(id);
  }
}
