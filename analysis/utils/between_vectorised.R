# vectorised version of between()
between_vectorised = function(x, left, right){
  (x >= left) & (x <= right)
}