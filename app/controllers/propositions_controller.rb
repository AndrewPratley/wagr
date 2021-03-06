class PropositionsController < ApplicationController

  def logged_in?
    if User.find_by(id: session[:user_id])
      return true
    else
      return false
    end
  end

  def index
    # if user.admin?
    @user = session[:user_id]
    user_search = User.find_by(id: session[:user_id])
    @props = Proposition.last(6)
    @prop_popular = Proposition.first(6).reverse
    @current_wagers = user_search.bets.count
    @current_propositions = user_search.propositions.count
    @profit_30 = "70"
    @profit_all = "340"
    # need to go into bets and count proposition_id and sort by that - this site tells exactly how to do it (I didn't have time to figure this out) - http://stackoverflow.com/questions/8696005/rails-3-activerecord-order-by-count-on-association
    if logged_in?
      render :index
    else
      redirect_to '/'
    end
  end

  def new
    # to access the error messages if it doesn't save from create and renders this page again, use @prop.errors
    render :new
  end

  def create
    @prop = Proposition.new
    @prop.title = params[:title]
    @prop.description = params[:description]
    @prop.image = params[:image]
    @prop.deadline = params[:deadline]
    @prop.user_id = params[:user_id]
    @prop.category = params[:categories]
    if @prop.save
      redirect_to "/propositions/#{@prop.id}"
    else
      render :new
    end
  end

  def show
    # you want to show error messages flash[:title] and flash[:notice] if they exist (see edit and destroy methods below)
    user_search = User.find_by(id: session[:user_id])
    @prop = Proposition.find(params[:id])
    if logged_in?
      @current_wagers = user_search.bets.count
      @current_propositions = user_search.propositions.count
    end
    @profit_30 = "70"
    @profit_all = "340"
    render :show
    # to show the proposition's bets under the proposition, do a loop with @prop.bets
  end

  def category_show
    @props = Proposition.select { |prop| prop.category == params[:category] }

    @category = params[:category]

    case @category
      when "tv_shows"
        @category_title = 'TV Shows'
      when "movies"
        @category_title = 'Movies'
      when "sport"
        @category_title = 'Sports'
      when "celebrity"
        @category_title = 'Celebrity'
      when "people"
        @category_title = 'People'
      when "politics"
        @category_title = 'Politics'
      when "games"
        @category_title = 'Games'
      when "other"
        @category_title = 'Other'
    end

    render "propositions/category.html.erb"
  end


  def edit
    # to access the error messages, it will be @prop.errors
    @prop = Proposition.find(params[:id])
    if @prop.bets.count < 2
      render :edit
    else
      flash[:title]='Error!'
      flash[:notice]='You can no longer edit your proposition.'
      redirect_to "/propositions/#{@prop.id}"
    end
  end

  def update
    @prop = Proposition.find(params[:id])
    @prop.title = params[:title]
    @prop.description = params[:description]
    @prop.image = params[:image]
    @prop.deadline = params[:deadline]
    @prop.category = params[:categories]
    if @prop.save
      redirect_to "/propositions/#{@prop.id}"
    else
      render :new
    end
  end

  def destroy
    @prop = Proposition.find(params[:id])
    @prop.bets.destroy_all
    @prop.destroy
    redirect_to '/dashboard'
  end

  def destroy_admin
    @prop = Proposition.find(params[:id])
    @prop.bets.destroy
    @prop.destroy
    redirect_to '/dashboard'
  end

  def decide_referee
    arr_to_decide = Proposition.select { |prop| prop.outcome == "nil" && prop.deadline < DateTime.now }
    if arr_to_decide.length >= 1
      @prop = arr_to_decide.sort_by { |k| k["updated_at"] }.first
      redirect_to "/propositions/#{@prop.id}"
    else
      render "/propositions/end.html.erb"
    end
  end

  def outcome_decided
    @prop = Proposition.find(params[:id])
    @prop.outcome = params[:outcome]
    @prop.save

    arr_of_trues = @prop.bets.select { |bet| bet.bet_side == true }.sort_by { |k| k["updated_at"] }
    arr_of_falses = @prop.bets.select { |bet| bet.bet_side == false }.sort_by { |k| k["updated_at"] }
    num_of_trues = arr_of_trues.count
    num_of_falses = arr_of_falses.count

    if num_of_falses > num_of_trues
      arr_of_falses = arr_of_falses.first(num_of_trues)
    elsif num_of_falses < num_of_trues
      arr_of_trues = arr_of_trues.first(num_of_falses)
    end

    if params[:outcome] == "true"
      arr_of_trues.each do |bet|
        u = User.find(bet.user_id)
        u.account_balance += 20
        u.save
      end
      arr_of_falses.each do |bet|
        u = User.find(bet.user_id)
        u.account_balance -= 10
        u.save
      end
    end

    if params[:outcome] == "false"
      arr_of_trues.each do |bet|
        u = User.find(bet.user_id)
        u.account_balance -= 10
        u.save
      end
      arr_of_falses.each do |bet|
        u = User.find(bet.user_id)
        u.account_balance += 20
        u.save
      end
    end
    redirect_to '/referee'
  end

end
