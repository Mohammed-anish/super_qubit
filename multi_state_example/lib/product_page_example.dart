import 'package:super_qubit/super_qubit.dart';

// ============================================================================
// MODELS
// ============================================================================

class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final List<String> images;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.images,
    required this.rating,
  });
}

class Review {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

// ============================================================================
// PRODUCT DETAILS QUBIT - Manages product loading and data
// ============================================================================

abstract class ProductEvent {}

class LoadProductEvent extends ProductEvent {
  final String productId;
  LoadProductEvent(this.productId);
}

class ProductState {
  final bool isLoading;
  final Product? product;
  final String? error;

  ProductState({
    this.isLoading = false,
    this.product,
    this.error,
  });

  ProductState copyWith({
    bool? isLoading,
    Product? product,
    String? error,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      product: product ?? this.product,
      error: error ?? this.error,
    );
  }
}

class ProductDetailsQubit extends Qubit<ProductEvent, ProductState> {
  ProductDetailsQubit() : super(ProductState()) {
    on<LoadProductEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true, error: null));

      try {
        // Simulate API call
        await Future.delayed(Duration(seconds: 1));
        final product = Product(
          id: event.productId,
          name: 'Premium Wireless Headphones',
          price: 299.99,
          description: 'High-quality wireless headphones with noise cancellation',
          images: [
            'image1.jpg',
            'image2.jpg',
            'image3.jpg',
            'image4.jpg',
          ],
          rating: 4.5,
        );

        emit(state.copyWith(isLoading: false, product: product));

        // Cross-communication: Load gallery images when product loads
        dispatch<ImageGalleryQubit, SetImagesEvent>(
          SetImagesEvent(product.images),
        );

        // Cross-communication: Load reviews when product loads
        dispatch<ReviewsQubit, LoadReviewsEvent>(
          LoadReviewsEvent(event.productId),
        );

        // Cross-communication: Load related products
        dispatch<RelatedProductsQubit, LoadRelatedEvent>(
          LoadRelatedEvent(event.productId),
        );
      } catch (e) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    });
  }
}

// ============================================================================
// IMAGE GALLERY QUBIT - Manages image carousel and zoom
// ============================================================================

abstract class GalleryEvent {}

class SetImagesEvent extends GalleryEvent {
  final List<String> images;
  SetImagesEvent(this.images);
}

class SelectImageEvent extends GalleryEvent {
  final int index;
  SelectImageEvent(this.index);
}

class ToggleZoomEvent extends GalleryEvent {}

class GalleryState {
  final List<String> images;
  final int currentIndex;
  final bool isZoomed;

  GalleryState({
    this.images = const [],
    this.currentIndex = 0,
    this.isZoomed = false,
  });

  GalleryState copyWith({
    List<String>? images,
    int? currentIndex,
    bool? isZoomed,
  }) {
    return GalleryState(
      images: images ?? this.images,
      currentIndex: currentIndex ?? this.currentIndex,
      isZoomed: isZoomed ?? this.isZoomed,
    );
  }
}

class ImageGalleryQubit extends Qubit<GalleryEvent, GalleryState> {
  ImageGalleryQubit() : super(GalleryState()) {
    on<SetImagesEvent>((event, emit) {
      emit(state.copyWith(images: event.images, currentIndex: 0));
    });

    on<SelectImageEvent>((event, emit) {
      emit(state.copyWith(currentIndex: event.index, isZoomed: false));
    });

    on<ToggleZoomEvent>((event, emit) {
      emit(state.copyWith(isZoomed: !state.isZoomed));
    });
  }
}

// ============================================================================
// REVIEWS QUBIT - Manages reviews with pagination and filtering
// ============================================================================

abstract class ReviewEvent {}

class LoadReviewsEvent extends ReviewEvent {
  final String productId;
  LoadReviewsEvent(this.productId);
}

class LoadMoreReviewsEvent extends ReviewEvent {}

class FilterReviewsEvent extends ReviewEvent {
  final int? minRating;
  FilterReviewsEvent(this.minRating);
}

class ReviewsState {
  final bool isLoading;
  final List<Review> reviews;
  final int? filterMinRating;
  final int currentPage;
  final bool hasMore;

  ReviewsState({
    this.isLoading = false,
    this.reviews = const [],
    this.filterMinRating,
    this.currentPage = 0,
    this.hasMore = true,
  });

  ReviewsState copyWith({
    bool? isLoading,
    List<Review>? reviews,
    int? filterMinRating,
    int? currentPage,
    bool? hasMore,
  }) {
    return ReviewsState(
      isLoading: isLoading ?? this.isLoading,
      reviews: reviews ?? this.reviews,
      filterMinRating: filterMinRating ?? this.filterMinRating,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  List<Review> get filteredReviews {
    if (filterMinRating == null) return reviews;
    return reviews.where((r) => r.rating >= filterMinRating!).toList();
  }
}

class ReviewsQubit extends Qubit<ReviewEvent, ReviewsState> {
  ReviewsQubit() : super(ReviewsState()) {
    on<LoadReviewsEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));

      try {
        // Simulate API call
        await Future.delayed(Duration(milliseconds: 800));
        final reviews = _generateMockReviews(10);

        emit(state.copyWith(
          isLoading: false,
          reviews: reviews,
          currentPage: 1,
        ));
      } catch (e) {
        emit(state.copyWith(isLoading: false));
      }
    });

    on<LoadMoreReviewsEvent>((event, emit) async {
      if (!state.hasMore) return;

      emit(state.copyWith(isLoading: true));

      try {
        await Future.delayed(Duration(milliseconds: 500));
        final newReviews = _generateMockReviews(5);

        emit(state.copyWith(
          isLoading: false,
          reviews: [...state.reviews, ...newReviews],
          currentPage: state.currentPage + 1,
          hasMore: state.currentPage < 3, // Max 3 pages
        ));
      } catch (e) {
        emit(state.copyWith(isLoading: false));
      }
    });

    on<FilterReviewsEvent>((event, emit) {
      emit(state.copyWith(filterMinRating: event.minRating));
    });
  }

  List<Review> _generateMockReviews(int count) {
    return List.generate(
      count,
      (i) => Review(
        id: 'review_$i',
        userName: 'User ${i + 1}',
        rating: 3.0 + (i % 3),
        comment: 'Great product! Highly recommended.',
        date: DateTime.now().subtract(Duration(days: i)),
      ),
    );
  }
}

// ============================================================================
// CART QUBIT - Manages add to cart with animation state
// ============================================================================

abstract class CartEvent {}

class AddToCartEvent extends CartEvent {
  final String productId;
  final int quantity;
  AddToCartEvent(this.productId, this.quantity);
}

class ResetCartAnimationEvent extends CartEvent {}

class CartState {
  final int itemCount;
  final bool showAddAnimation;
  final String? lastAddedProductId;

  CartState({
    this.itemCount = 0,
    this.showAddAnimation = false,
    this.lastAddedProductId,
  });

  CartState copyWith({
    int? itemCount,
    bool? showAddAnimation,
    String? lastAddedProductId,
  }) {
    return CartState(
      itemCount: itemCount ?? this.itemCount,
      showAddAnimation: showAddAnimation ?? this.showAddAnimation,
      lastAddedProductId: lastAddedProductId ?? this.lastAddedProductId,
    );
  }
}

class CartQubit extends Qubit<CartEvent, CartState> {
  CartQubit() : super(CartState()) {
    on<AddToCartEvent>((event, emit) async {
      emit(state.copyWith(
        itemCount: state.itemCount + event.quantity,
        showAddAnimation: true,
        lastAddedProductId: event.productId,
      ));

      // Auto-reset animation after 2 seconds
      await Future.delayed(Duration(seconds: 2));
      add(ResetCartAnimationEvent());
    });

    on<ResetCartAnimationEvent>((event, emit) {
      emit(state.copyWith(showAddAnimation: false));
    });
  }
}

// ============================================================================
// RELATED PRODUCTS QUBIT - Manages product recommendations
// ============================================================================

abstract class RelatedEvent {}

class LoadRelatedEvent extends RelatedEvent {
  final String productId;
  LoadRelatedEvent(this.productId);
}

class RelatedProductClickedEvent extends RelatedEvent {
  final String productId;
  RelatedProductClickedEvent(this.productId);
}

class RelatedProductsState {
  final bool isLoading;
  final List<Product> products;

  RelatedProductsState({
    this.isLoading = false,
    this.products = const [],
  });

  RelatedProductsState copyWith({
    bool? isLoading,
    List<Product>? products,
  }) {
    return RelatedProductsState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
    );
  }
}

class RelatedProductsQubit extends Qubit<RelatedEvent, RelatedProductsState> {
  RelatedProductsQubit() : super(RelatedProductsState()) {
    on<LoadRelatedEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));

      try {
        await Future.delayed(Duration(milliseconds: 600));
        final products = List.generate(
          4,
          (i) => Product(
            id: 'related_$i',
            name: 'Related Product ${i + 1}',
            price: 99.99 + (i * 50),
            description: 'Similar product you might like',
            images: ['related_$i.jpg'],
            rating: 4.0 + (i * 0.1),
          ),
        );

        emit(state.copyWith(isLoading: false, products: products));
      } catch (e) {
        emit(state.copyWith(isLoading: false));
      }
    });

    on<RelatedProductClickedEvent>((event, emit) {
      // Cross-communication: Load new product when related product clicked
      dispatch<ProductDetailsQubit, LoadProductEvent>(
        LoadProductEvent(event.productId),
      );

      // Also reset the gallery
      dispatch<ImageGalleryQubit, SelectImageEvent>(SelectImageEvent(0));
    });
  }
}

// ============================================================================
// SUPER QUBIT - Orchestrates all micro-states
// ============================================================================

/// This is where the magic happens!
/// Instead of managing 5 separate BLoCs with complex coordination,
/// we have ONE SuperQubit managing all states with built-in cross-communication.
///
/// Traditional Bloc approach would require:
/// - 5 separate BLoC/Cubit classes
/// - Multiple BlocListeners for cross-communication
/// - Complex event bubbling
/// - Manual coordination logic scattered across widgets
///
/// With SuperQubit:
/// - Single entry point
/// - Built-in cross-communication
/// - Centralized coordination logic
/// - Clean state management
class ProductPageSuperQubit extends SuperQubit {
  ProductPageSuperQubit() {
    // Parent-level handler: Track all add-to-cart events
    on<CartQubit, AddToCartEvent>((event, emit) {
      print('✓ Item added to cart! Quantity: ${event.quantity}');

      // Could trigger analytics, show notification, etc.
      // This is coordination logic at the parent level
    });

    // Parent-level handler: Track when users view related products
    on<RelatedProductsQubit, RelatedProductClickedEvent>((event, emit) {
      print('✓ User clicked related product: ${event.productId}');

      // Could track user behavior, update recommendations, etc.
      // The cross-communication to load new product is handled by the child
    });

    // Cross-state validation example
    // Prevent adding to cart if product is still loading
    on<CartQubit, AddToCartEvent>((event, emit) {
      final productState = getState<ProductDetailsQubit, ProductState>();

      if (productState.isLoading) {
        print('⚠ Cannot add to cart: Product still loading');
        // Could emit an error state or show a message
        return;
      }
    });
  }

  @override
  void registerQubits(List<BaseQubit> qubits) {
    super.registerQubits(qubits);

    // Setup listeners after Qubits are registered
    // Listen to product details loading
    // When product loads successfully, automatically update related states
    listenTo<ProductDetailsQubit>((state) {
      if (state is ProductState && state.product != null && !state.isLoading) {
        print('✓ Product loaded: ${state.product!.name}');
        print('  → Triggered image gallery, reviews, and related products');
      }
    });

    // Listen to review filtering
    // When reviews are filtered, scroll could be reset (UI coordination)
    listenTo<ReviewsQubit>((state) {
      if (state is ReviewsState && state.filterMinRating != null) {
        print('✓ Reviews filtered by rating: ${state.filterMinRating}+');
      }
    });

    // Listen to cart changes to show notifications
    listenTo<CartQubit>((state) {
      if (state is CartState && state.showAddAnimation) {
        print('✓ Playing add-to-cart animation');
      }
    });
  }

  // Convenience getters for accessing child Qubits
  ProductDetailsQubit get product => getQubit<ProductDetailsQubit>();
  ImageGalleryQubit get gallery => getQubit<ImageGalleryQubit>();
  ReviewsQubit get reviews => getQubit<ReviewsQubit>();
  CartQubit get cart => getQubit<CartQubit>();
  RelatedProductsQubit get related => getQubit<RelatedProductsQubit>();

  // High-level actions that coordinate multiple Qubits
  Future<void> loadProductPage(String productId) async {
    print('\n🚀 Loading product page: $productId');
    print('─────────────────────────────────────');
    await product.add(LoadProductEvent(productId));
  }

  Future<void> addProductToCart(int quantity) async {
    final productState = product.state;
    if (productState.product != null) {
      await cart.add(AddToCartEvent(productState.product!.id, quantity));
    }
  }

  Future<void> viewRelatedProduct(String productId) async {
    await related.add(RelatedProductClickedEvent(productId));
  }
}
