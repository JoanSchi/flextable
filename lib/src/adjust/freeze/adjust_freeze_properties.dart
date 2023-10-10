// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class AdjustFreezeProperties {
  const AdjustFreezeProperties(
      {this.useMoveFreezePosition = true, this.sizeMoveFreezeButton = 50.0});

  final bool useMoveFreezePosition;
  final double sizeMoveFreezeButton;
}
