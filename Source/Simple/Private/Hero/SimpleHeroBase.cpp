// Fill out your copyright notice in the Description page of Project Settings.


#include "Hero/SimpleHeroBase.h"
#include "Camera/SimpleCameraComponent.h"
#include "Component/SimpleInputComponent.h"
#include "Component/SimpleHealthComponent.h"

ASimpleHeroBase::ASimpleHeroBase(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	SimpleCameraComponent = CreateDefaultSubobject<USimpleCameraComponent>(TEXT("SimpleCameraComponent"));
	SimpleCameraComponent->SetRelativeLocation(FVector(-300.0f, 0.0f, 75.0f));

	SimpleInputComponent = CreateDefaultSubobject<USimpleInputComponent>(TEXT("SimpleInputComponent"));

	SimpleHealthComponent = CreateDefaultSubobject<USimpleHealthComponent>(TEXT("HealthComponent"));
	SimpleHealthComponent->OnDeathStarted.AddDynamic(this, &ThisClass::OnDeathStarted);
	SimpleHealthComponent->OnDeathFinished.AddDynamic(this, &ThisClass::OnDeathFinished);

	BaseEyeHeight = 80.0f;
	CrouchedEyeHeight = 50.0f;
}

void ASimpleHeroBase::PostInitializeComponents()
{
	Super::PostInitializeComponents();

	if (SimpleCameraComponent)
	{
		SimpleCameraComponent->SetupDefaultCameraMode();
	}
}

// Called to bind functionality to input
void ASimpleHeroBase::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	if (SimpleInputComponent)
	{
		SimpleInputComponent->SetupPlayerInputComponent(PlayerInputComponent);
	}
}

void ASimpleHeroBase::OnInitializedAbilitySystem()
{
	Super::OnInitializedAbilitySystem();

	SimpleInputComponent->AbilitySystemComponent = AbilitySystemComponent;

	SimpleHealthComponent->InitializeWithAbilitySystem(AbilitySystemComponent);
}
