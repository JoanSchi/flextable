// class ImmutableWrapper<T> {
//   final T object;

//   ImmutableWrapper(
//     this.object,
//   );
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is ImmutableWrapper<T> && other.object == object;
//   }

//   @override
//   int get hashCode => object.hashCode;
// }
