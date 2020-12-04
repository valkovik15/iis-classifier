require 'daru'
require 'matrix'

fare_max = Daru::DataFrame.from_csv("train.csv")['Fare'].max()
age_max = Daru::DataFrame.from_csv("train.csv")['Age'].max()
  
def get_df(path, range)
    d = Daru::DataFrame.from_csv(path)[ 'Pclass', 'Sex', 'Age', 'SibSp', 'Parch', 'Fare', 'Survived'].row_at(range).replace_values('male', 0).replace_values('female', 1).filter_rows{ |row| row['Age'] }
    d['new_index'] = (0...d.shape[0])
    d.set_index('new_index')
    return [d['Survived'], d['Pclass', 'Sex', 'Age', 'SibSp', 'Parch', 'Fare']]
end

def euclidean_distance(point1, point2)
    Math.sqrt(point1.zip(point2).reduce(0) { |sum, p| sum + (p[0] - p[1]) ** 2 })
end

y_train, d = get_df('train.csv', 0..375)
d['Fare'] = d['Fare'] / fare_max
d['Age'] = d['Age'] / age_max
train_df = d
y_par, d = get_df('train.csv', 376..750)
d['Fare'] = d['Fare'] / fare_max
d['Age'] = d['Age'] / age_max
parametric_df = d

y_test, d = get_df('train.csv', 751..890)
d['Fare'] = d['Fare'] / fare_max
d['Age'] = d['Age'] / age_max
test_df = d

distance_matrix = Matrix.build(train_df.shape[0], parametric_df.shape[0]) {|row, col| euclidean_distance(train_df.row_at(row), parametric_df.row_at(col))}.to_a
b = Matrix.build(train_df.shape[0], 2) {0}.to_a

target_qual = 0.75

est_qual = 0

k = 0
best_k = 1

while est_qual < target_qual do
    k+=1
    right_pred = 0
        (0...train_df.shape[0]).each do |row|
            [0, 1].each do |cls|
                clf_ind = y_par.where(y_par.eq(cls)).index.to_a
                b[row][cls] = distance_matrix[row].values_at(*clf_ind).min(k).sum
            end
            pred_cls = b[row].rindex(b[row].min)
            real_cls = y_train[row]
            right_pred+=1 if pred_cls==real_cls
        end
        est_qual = right_pred.to_f/train_df.shape[0].to_f
        p "For k=#{k} quality is #{est_qual}"
end

p 'Starting quality test:'

new_d = Matrix.build(test_df.shape[0], parametric_df.shape[0]) {|row, col| euclidean_distance(test_df.row_at(row), parametric_df.row_at(col))}.to_a
right_pred = 0
        (0...test_df.shape[0]).each do |row|
            [0, 1].each do |cls|
                clf_ind = y_par.where(y_par.eq(cls)).index.to_a
                b[row][cls] = new_d[row].values_at(*clf_ind).min(k).sum
            end
            pred_cls = b[row].rindex(b[row].min)
            real_cls = y_test[row]
            right_pred+=1 if pred_cls==real_cls
        end
        est_qual = right_pred.to_f/test_df.shape[0].to_f
        p "For k=#{k} quality is #{est_qual} on test set"
    k+=1
