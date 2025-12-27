import 'package:super_qubit/super_qubit.dart';

class QubitTestSuperCubit extends SuperQubit {
  QubitTestSuperCubit() {
    on<ChildQubit1, Event1>((event, emit) {
      emit(State1Success());
    });
  }
}

class Event1 {}

class State1 {}

class State1Initial extends State1 {}

class State1Success extends State1 {}

class ChildQubit1 extends Qubit<Event1, State1> {
  ChildQubit1() : super(State1Initial()){
    
  }
}

class CrossCommunication extends Qubit<Event1, State1> {
  CrossCommunication() : super(State1Initial());
}
