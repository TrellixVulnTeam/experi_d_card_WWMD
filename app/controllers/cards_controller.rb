class CardsController < ApplicationController
  before_action :set_card, only: [:show, :edit, :update, :destroy]
  require "rexml/document"
  require "shellwords"
  require "securerandom"
  include REXML

  # GET /cards
  # GET /cards.json
  def index
    #@cards = Card.all
  end

  # GET /cards/1
  # GET /cards/1.json
  def show
  end

  # GET /cards/new
  def new
    @card = Card.new
    @prefectural = Prefectural.all
    @papers = PaperTemplate.all
    @cards = CardTemplate.all
    @course = [Course.new(name: "学部を選択してください", id:"")]
    @laboratory = [Laboratory.new(name: "学部を選択してください", id:"")]
  end

  # GET /cards/1/edit
  def edit
  end

  # POST /cards
  # POST /cards.json
  def create
    @card = Card.new(card_params)
    mm = 3.543307
    forms = params.require(:card).permit(:name, :kana_name, :department, :postalcode, :address_prefectural, :address_city, :address_street, :address_building, :tel, :email, :course, :laboratory, :free_text, :card_template, :paper_template)

    paper_template = PaperTemplate.find(forms[:paper_template])
    paper = File.read("app/assets/images/paper/" + paper_template.path)

    card_template = CardTemplate.find(forms[:card_template])
    svg = REXML::Document.new(open("app/assets/images/card/" + card_template.path))

    # jikanganai
    svg.root.elements["//*[@id='text_name']"].text = forms[:name]

    if card_template.department
      if forms[:department].present?
        svg.root.elements["//*[@id='text_department']"].text =  School.find(Department.find(forms[:department]).school).name + Department.find(forms[:department]).name
      else 
        svg.root.elements["//*[@id='text_department']"].text = ""
      end
    end

    if card_template.course and forms[:course]
      if forms[:course].present?
        svg.root.elements["//*[@id='text_course']"].text = Course.find(forms[:course]).name
      else
        svg.root.elements["//*[@id='text_course']"].text =  ""
      end
    end

    
    if card_template.laboratory and forms[:laboratory]
      if forms[:laboratory].present?
        svg.root.elements["//*[@id='text_lab']"].text = Laboratory.find(forms[:laboratory]).name
      else
        svg.root.elements["//*[@id='text_lab']"].text =  ""
      end
    end

    if card_template.tel
      if forms[:tel].present?
        svg.root.elements["//*[@id='text_tel']"].text = forms[:tel]
      else
        svg.root.elements["//*[@id='text_tel']"].text = ""
      end
    end

    if card_template.email
      if forms[:email].present?
        svg.root.elements["//*[@id='text_email']"].text = forms[:email]
      else
        svg.root.elements["//*[@id='text_email']"].text = ""
      end
    end

    if card_template.free
      if forms[:free_text].present?
        svg.root.elements["//*[@id='text_free']"].text = forms[:free_text]
      else
        svg.root.elements["//*[@id='text_free']"].text = ""
      end
    end

    if card_template.address_city
      if forms[:address_city].present?
        svg.root.elements["//*[@id='text_address']"].text = Prefectural.find(forms[:address_prefectural]).name + forms[:address_city] + forms[:address_street] + forms[:address_building]
      else
        svg.root.elements["//*[@id='text_address']"].text = ""
      end
    end

    card_text = ""
    xMargin = paper_template.margin_x * mm
    yMargin = paper_template.margin_y * mm
    xSize = card_template.size_x * mm
    ySize = card_template.size_y * mm
    debug = ""
    for xNum in 0..(paper_template.cols - 1) do
      for yNum in 0..(paper_template.rows - 1) do
        x = xMargin + xSize * xNum
        y = yMargin + ySize * yNum
        svgText = svg.root.to_s
        
        svgText.gsub!(/<svg[^>]+>/, '')
        svgText.gsub!(/<\/svg>/, '')
        svgText.gsub!(/id='([^']+)'/) { "id='" + $1 + xNum.to_s + "_" + yNum.to_s + "'" }
        svgText.gsub!(/x='([0-9.]+)'/) { "x='" + ($1.to_f + x).to_s + "'" }
        svgText.gsub!(/y='([0-9.]+)'/) { "y='" + ($1.to_f + y).to_s + "'" }
        svgText.gsub!(/d='m ([0-9.]+),([0-9.]+)/) { "d='m #{($1.to_f + x).to_s},#{($2.to_f + y).to_s}" }

        paper.gsub!(/<g \/>/, svgText + "<g />")
      end
    end
    paper.gsub!(/"/, "'")

    filename = SecureRandom.hex
    svgFile = File.open("tmp/#{filename}.svg", 'w')
    svgFile.puts paper
    pdf = `cat tmp/#{filename}.svg | cairosvg -` 
    svgFile.close
    File.unlink("tmp/#{filename}.svg")

    #pdf = `echo "#{paper}" | cairosvg -`
    send_data pdf, filename: "card.pdf", type: "application/pdf", disposition: "inline"
    
  end

  # PATCH/PUT /cards/1
  # PATCH/PUT /cards/1.json
  def update
    respond_to do |format|
      if @card.update(card_params)
        format.html { redirect_to @card, notice: 'Card was successfully updated.' }
        format.json { render :show, status: :ok, location: @card }
      else
        format.html { render :edit }
        format.json { render json: @card.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cards/1
  # DELETE /cards/1.json
  def destroy
    @card.destroy
    respond_to do |format|
      format.html { redirect_to cards_url, notice: 'Card was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # from: http://qiita.com/inodev/items/9e08261c658c87cf777d
  def get_area
    records = Area.search_area(params[:search_code])
    render json: records
  end

  # cards/update_courses
  def update_courses
    @course = Course.where("department_id = ?", params[:department])
    respond_to do |format|
      format.js
    end
  end

  # cards/update_laboratories
  def update_laboratories
    @laboratory = Laboratory.where("department_id = ?", params[:department])
    respond_to do |format|
      format.js
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_card
      @card = Card.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def card_params
      params[:card]
    end
end
