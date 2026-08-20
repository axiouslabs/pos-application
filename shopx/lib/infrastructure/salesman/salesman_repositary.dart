import 'package:shopx/domain/salesman/salesman.dart';
import 'package:shopx/infrastructure/salesman/salesman_api.dart';

class SalesmanRepository {
  final SalesmanApi api;

  SalesmanRepository(this.api);

  // CREATE
  Future<Salesman> createSalesman(Salesman salesman) async {
    final res = await api.createSalesman(salesman.toJson());
    return Salesman.fromJson(res);
  }

  // GET ALL
  Future<List<Salesman>> getAllSalesmen() async {
    final res = await api.getSalesmen();
    return res.map<Salesman>((json) => Salesman.fromJson(json)).toList();
  }

  // GET SINGLE
  Future<Salesman> getSalesmanById(int id) async {
    final json = await api.getSalesmanById(id);
    return Salesman.fromJson(json);
  }

  // UPDATE
  Future<Salesman> updateSalesman(int id, Salesman salesman) async {
    final res = await api.updateSalesman(id, salesman.toJson());
    return Salesman.fromJson(res);
  }

  // DELETE
  Future<void> deleteSalesman(int id) async {
    await api.deleteSalesman(id);
  }
}
 