template <class T>
struct GetTypeValue {
  static constexpr const bool value = T::value;
};

using Invalid = GetTypeValue<int>;
