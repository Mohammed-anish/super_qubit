import 'package:flutter/material.dart';
import 'package:super_qubit/super_qubit.dart';
import 'product_page_example.dart';

/// This demonstrates how CLEAN the UI code becomes with SuperQubit!
///
/// Compare this to traditional Bloc approach which would require:
/// - MultiBlocProvider with 5 nested providers
/// - Multiple BlocBuilder/BlocListener widgets
/// - Complex widget tree
/// - Manual coordination between different parts
///
/// With SuperQubit: Single provider, clean access, automatic coordination!
class ProductPageDemo extends StatelessWidget {
  const ProductPageDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QubitProvider(
      superQubit: ProductPageSuperQubit(),
      superStates: [
        ProductDetailsQubit(),
        ImageGalleryQubit(),
        ReviewsQubit(),
        CartQubit(),
        RelatedProductsQubit(),
      ],
      child: const ProductPageView(),
    );
  }
}

class ProductPageView extends StatefulWidget {
  const ProductPageView({Key? key}) : super(key: key);

  @override
  State<ProductPageView> createState() => _ProductPageViewState();
}

class _ProductPageViewState extends State<ProductPageView> {
  @override
  void initState() {
    super.initState();
    // Load product on page open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.readSuper<ProductPageSuperQubit>().loadProductPage('product_123');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          // Cart icon with badge - listening to CartQubit
          QubitBuilder<CartQubit, CartState>(
            superQubitType: ProductPageSuperQubit,
            builder: (context, state) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {},
                  ),
                  if (state.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: state.showAddAnimation ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${state.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery Section
            ImageGallerySection(),
            SizedBox(height: 16),

            // Product Details Section
            ProductDetailsSection(),
            SizedBox(height: 24),

            // Reviews Section
            ReviewsSection(),
            SizedBox(height: 24),

            // Related Products Section
            RelatedProductsSection(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// IMAGE GALLERY SECTION
// ============================================================================

class ImageGallerySection extends StatelessWidget {
  const ImageGallerySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QubitBuilder<ImageGalleryQubit, GalleryState>(
      superQubitType: ProductPageSuperQubit,
      builder: (context, state) {
        if (state.images.isEmpty) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          children: [
            // Main image
            GestureDetector(
              onTap: () {
                context
                    .readSuper<ProductPageSuperQubit>()
                    .gallery
                    .add(ToggleZoomEvent());
              },
              child: Container(
                height: state.isZoomed ? 500 : 300,
                width: double.infinity,
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: state.isZoomed ? 200 : 100,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.images[state.currentIndex],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: state.isZoomed ? 20 : 16,
                        ),
                      ),
                      if (state.isZoomed)
                        const Text(
                          'Tap to zoom out',
                          style: TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Thumbnail strip
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.images.length,
                itemBuilder: (context, index) {
                  final isSelected = index == state.currentIndex;
                  return GestureDetector(
                    onTap: () {
                      context
                          .readSuper<ProductPageSuperQubit>()
                          .gallery
                          .add(SelectImageEvent(index));
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image,
                          color: isSelected ? Colors.blue : Colors.grey[400],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// PRODUCT DETAILS SECTION
// ============================================================================

class ProductDetailsSection extends StatelessWidget {
  const ProductDetailsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QubitBuilder<ProductDetailsQubit, ProductState>(
      superQubitType: ProductPageSuperQubit,
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.error != null) {
          return Center(
            child: Text(
              'Error: ${state.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final product = state.product;
        if (product == null) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  Text(
                    ' ${product.rating} ',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    '(${_getReviewCount(context)} reviews)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                product.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.readSuper<ProductPageSuperQubit>().addProductToCart(1);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _getReviewCount(BuildContext context) {
    final superQubit = context.readSuper<ProductPageSuperQubit>();
    final reviewsState = superQubit.reviews.state;
    return reviewsState.reviews.length;
  }
}

// ============================================================================
// REVIEWS SECTION
// ============================================================================

class ReviewsSection extends StatelessWidget {
  const ReviewsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QubitBuilder<ReviewsQubit, ReviewsState>(
      superQubitType: ProductPageSuperQubit,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Customer Reviews',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<int?>(
                    value: state.filterMinRating,
                    hint: const Text('Filter'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 5, child: Text('5 stars')),
                      DropdownMenuItem(value: 4, child: Text('4+ stars')),
                      DropdownMenuItem(value: 3, child: Text('3+ stars')),
                    ],
                    onChanged: (value) {
                      context
                          .readSuper<ProductPageSuperQubit>()
                          .reviews
                          .add(FilterReviewsEvent(value));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.isLoading && state.reviews.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (state.filteredReviews.isEmpty)
                const Center(child: Text('No reviews yet'))
              else
                ...state.filteredReviews.take(3).map((review) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                review.userName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    Icons.star,
                                    size: 16,
                                    color: i < review.rating
                                        ? Colors.amber
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(review.comment),
                        ],
                      ),
                    ),
                  );
                }),
              if (state.hasMore)
                Center(
                  child: TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () {
                            context
                                .readSuper<ProductPageSuperQubit>()
                                .reviews
                                .add(LoadMoreReviewsEvent());
                          },
                    child: state.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Load More Reviews'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// RELATED PRODUCTS SECTION
// ============================================================================

class RelatedProductsSection extends StatelessWidget {
  const RelatedProductsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QubitBuilder<RelatedProductsQubit, RelatedProductsState>(
      superQubitType: ProductPageSuperQubit,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You May Also Like',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (state.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (state.products.isEmpty)
                const Center(child: Text('No recommendations'))
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return GestureDetector(
                        onTap: () {
                          context
                              .readSuper<ProductPageSuperQubit>()
                              .viewRelatedProduct(product.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 120,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 50,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
