class CourseWikisController < ApplicationController
  before_action :set_course_wiki, only: [:show, :edit, :update, :destroy]

  # GET /course_wikis
  # GET /course_wikis.json
  def index
    @course_wikis = CourseWiki.all
  end

  # GET /course_wikis/1
  # GET /course_wikis/1.json
  def show
  end

  # GET /course_wikis/new
  def new
    @course_wiki = CourseWiki.new
  end

  # GET /course_wikis/1/edit
  def edit
  end

  # POST /course_wikis
  # POST /course_wikis.json
  def create
    @course_wiki = CourseWiki.new(course_wiki_params)

    respond_to do |format|
      if @course_wiki.save
        format.html { redirect_to @course_wiki, notice: 'Course wiki was successfully created.' }
        format.json { render :show, status: :created, location: @course_wiki }
      else
        format.html { render :new }
        format.json { render json: @course_wiki.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /course_wikis/1
  # PATCH/PUT /course_wikis/1.json
  def update
    respond_to do |format|
      if @course_wiki.update(course_wiki_params)
        format.html { redirect_to @course_wiki, notice: 'Course wiki was successfully updated.' }
        format.json { render :show, status: :ok, location: @course_wiki }
      else
        format.html { render :edit }
        format.json { render json: @course_wiki.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /course_wikis/1
  # DELETE /course_wikis/1.json
  def destroy
    @course_wiki.destroy
    respond_to do |format|
      format.html { redirect_to course_wikis_url, notice: 'Course wiki was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_course_wiki
      @course_wiki = CourseWiki.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def course_wiki_params
      params.require(:course_wiki).permit(:course_id)
    end
end
