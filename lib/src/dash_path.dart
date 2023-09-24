import 'dart:ui';

/// Crea un nuevo camino (path) que se dibuja a partir de los segmentos de `source`.
///
/// Los intervalos de los trazos están controlados por `dashArray` - consulta [CircularIntervalList]
/// para ejemplos.
///
/// `dashOffset` especifica un punto de inicio inicial para los trazos.
///
/// Pasar un `source` que sea un camino vacío devolverá un camino vacío.
Path dashPath(
  Path source, {
  required CircularIntervalList<double> dashArray,
  DashOffset? dashOffset,
}) {
  dashOffset = dashOffset ?? const DashOffset.absolute(0.0);

  final Path dest = Path();
  for (final PathMetric metric in source.computeMetrics()) {
    double distance = dashOffset._calculate(metric.length);
    bool draw = true;
    while (distance < metric.length) {
      final double len = dashArray.next;
      if (draw) {
        dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
      }
      distance += len;
      draw = !draw;
    }
  }

  return dest;
}

// Enumeración que especifica el tipo de desplazamiento de trazos.
enum _DashOffsetType { Absolute, Percentage }

/// Especifica la posición de inicio de una serie de trazos en un camino, ya sea como
/// un porcentaje o un valor absoluto.
///
/// El valor interno no será nulo.
class DashOffset {
  /// Crea un DashOffset que se medirá como un porcentaje de la longitud
  /// del segmento que se está trazando.
  ///
  /// `percentage` se ajustará entre 0.0 y 1.0.
  DashOffset.percentage(double percentage)
      : _rawVal = percentage.clamp(0.0, 1.0),
        _dashOffsetType = _DashOffsetType.Percentage;

  /// Crea un DashOffset que se medirá en términos de píxeles absolutos
  /// a lo largo de la longitud de un segmento de [Path].
  const DashOffset.absolute(double start)
      : _rawVal = start,
        _dashOffsetType = _DashOffsetType.Absolute;

  final double _rawVal;
  final _DashOffsetType _dashOffsetType;

  double _calculate(double length) {
    return _dashOffsetType == _DashOffsetType.Absolute
        ? _rawVal
        : length * _rawVal;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is DashOffset &&
        other._rawVal == _rawVal &&
        other._dashOffsetType == _dashOffsetType;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hash(_rawVal, _dashOffsetType);
}

/// Una lista circular de desplazamientos y longitudes de trazos.
///
/// Por ejemplo, la lista `[5, 10]` resultaría en trazos de 5 píxeles de largo
/// seguidos de espacios en blanco de 10 píxeles de largo. La lista `[5, 10, 5]`
/// resultaría en un trazo de 5 píxeles, un espacio de 10 píxeles, un trazo de 5 píxeles,
/// un espacio de 5 píxeles, un trazo de 10 píxeles, etc.
///
/// Ten en cuenta que esto no se ajusta completamente a un [Iterable<T>], ya que no tiene un moveNext.
class CircularIntervalList<T> {
  CircularIntervalList(this._vals);

  final List<T> _vals;
  int _idx = 0;

  T get next {
    if (_idx >= _vals.length) {
      _idx = 0;
    }
    return _vals[_idx++];
  }
}
